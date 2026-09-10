# HealthPod Blood Pressure Analyser

A headless Python service that runs alongside a Solid server. A HealthPod app
shares its blood pressure readings with the **Analyser Pod** and then calls the
service over gRPC; the service reads the readings, averages them, and shares
the results back:

1. it reads the blood pressure readings shared with the Analyser, per Pod;
2. it computes each Pod's average, and the average of those averages;
3. it shares the caller's own average, the cohort average, and a chart of the
   caller's readings back to the caller's Pod.

Results are written to local disk as JSON and PNG as well, and a small
read-only HTTP API serves them to a front end.

- Lives at `healthpod/analyser/bp_analyser`, a self-contained project under
  `healthpod/analyser/`, which holds one such project per analyser
- Analyser Pod address: configured in `config.yaml`, default
  `https://solid.dev.empwr.au/Analyser/profile/card#me`
- Runs continuously under systemd, waiting for an app to ask

## What changed, and why

This service used to watch rather than wait. It polled the Analyser Pod's
`healthpod/shared/shared-keys.ttl` every thirty seconds and ran a cycle
whenever its entity tag changed, which is what happens the moment somebody
shares a reading. It worked, and it was slow in three separate ways:

- **the user waited for the poll.** Pressing **Analyse** shared the readings
  and then waited up to `poll_seconds` for the service to notice;
- **every cycle worked for everybody.** With no way of knowing who had asked,
  a run computed, charted and published for every contributing Pod, so the
  person waiting paid for everyone else's results as well;
- **cancelling went the same road backwards.** The app had no route to the
  service — its HTTP interface binds to the server's loopback address — so it
  left a JSON marker in the one folder the Analyser Pod leaves publicly
  writable and then watched for it to disappear. An idle service collected
  markers once per poll, so the app spun for up to forty seconds before it
  could say whether anything had stopped, and often could not say at all.

Now the app asks. It still shares its readings — that is what gives the
analyser the keys to read them — and then makes one gRPC call naming itself.
The analysis runs inside that call and the reply is the finished result. The
poll is gone, the run works for the caller alone, and cancelling is a second
call answered out of memory in milliseconds.

## Contents

- [How it works](#how-it-works)
- [The gRPC interface](#the-grpc-interface)
- [Preparing the Analyser Pod](#preparing-the-analyser-pod)
- [Installing on the Solid server](#installing-on-the-solid-server)
- [Configuration](#configuration)
- [Running it](#running-it)
- [How a user asks for an analysis](#how-a-user-asks-for-an-analysis)
- [What the caller receives back](#what-the-caller-receives-back)
- [The results document](#the-results-document)
- [The front-end API](#the-front-end-api)
- [Privacy and security](#privacy-and-security)
- [Troubleshooting](#troubleshooting)
- [Development](#development)
- [Known limitations](#known-limitations)

## How it works

HealthPod stores each blood pressure reading as its own encrypted file in the
owner's Pod:

```
https://<server>/<pod>/healthpod/data/blood_pressure/bp_2026-08-19T09-15-00.json.enc.ttl
```

When the owner shares one of those files (or the whole folder) with the
Analyser's WebID, `solidpod` does three things: it updates the file's ACL, it
seals the file's encryption key with the Analyser's RSA public key and writes
it into the **Analyser's** `healthpod/shared/shared-keys.ttl`, and it appends a
line to the Analyser's permission log.

That shared-keys file is the index of everything the Analyser may read. It is
no longer the trigger: the app is.

```
                      ┌──────────── Solid server ─────────────┐
                      │                                        │
   Alice's HealthPod  │  Alice's Pod                           │
        │             │    healthpod/data/blood_pressure/*.enc.ttl
        │  1. share ──┼──►  (ACL + key sealed for the Analyser)
        │             │              │                         │
        │             │              ▼                         │
        │             │  Analyser's Pod                        │
        │             │    healthpod/shared/shared-keys.ttl    │
        │             │    healthpod/encryption/enc-keys.ttl   │
        │             └────────────────┬───────────────────────┘
        │                              │ 3. read and decrypt
        │  2. Analyse(web_id) ──►  ┌───┴──────────────┐
        │  ◄── the finished run    │  bp_analyser     │
        │                          │  (this service)  │
        │  2a. Cancel(web_id) ──►  └───┬──────────────┘
        │                              │ 4. publish + share back
        │             ┌────────────────▼───────────────────────┐
        │             │  Analyser's Pod                        │
        └── 5. read ──┼──  healthpod/data/analyser/<pod-id>/bp-average.json.enc.ttl
                      └────────────────┬───────────────────────┘
                                       ▼
                          var/results/latest.json
                                       │
                                       ▼
                       read-only HTTP API ──► front end
```

One cycle:

| Step | Module | What happens |
|------|--------|--------------|
| 0 | `grpc_server.py` | Take the Analyse call, note who is asking, and wait for a turn — analyses are serialised. |
| 1 | `keys.py` | Unlock the Analyser Pod: stretch the security key into the master key, verify it, open the RSA private key. Done once, at start-up, and reused. |
| 2 | `keys.py` | Read `shared-keys.ttl` and open each entry with the private key, revealing the shared resource URL and its AES key. |
| 3 | `discovery.py` | Keep the entries that look like blood pressure data, expand shared folders, and group everything by owner Pod. |
| 4 | `bp_data.py` | Fetch and decrypt each file, and parse the readings. |
| 5 | `statistics.py` | Average per Pod, then average those averages across the cohort. |
| 6 | `store.py`, `charts.py` | Write `var/results/latest.json`, and draw the caller's chart. |
| 7 | `publisher.py` | Encrypt the caller's result with that resource's own key — the same one every run — write it into the Analyser Pod, grant the caller read access, hand over the key (replacing any earlier one, then reading it back to confirm), and log the grant. |
| 8 | `grpc_server.py` | Answer the call with what was computed and where it was published. |

Steps 2 to 5 read every Pod that has shared data, because the cohort figure is
the average of every contributor's average and there is no way round that.
Steps 6 and 7 deal with the caller alone, and that is where the time went: a
run costs one chart and one publication rather than one of each per
contributing Pod.

Between every pair of steps the cycle asks whether it has been cancelled. The
answer is a flag in memory, set by a Cancel call on another thread, so it costs
nothing to ask and nothing is left half written when the answer is yes.

The cryptography in `crypto.py` matches `solidpod` exactly — Argon2id + HKDF
for the master key, AES counter mode with PKCS7 for content, AES-CBC for the
private key, RSA PKCS#1 v1.5 for sharing — and is verified against test vectors
generated by solidpod's own Dart libraries (see [Development](#development)).

## The gRPC interface

The contract lives in `bp_analyser/analyser.proto`, and that file is the only
place it is written down. Both halves are generated from it and committed, so
neither the service nor the app needs a protobuf compiler to build — only
whoever changes the contract does:

```bash
./proto.sh          # both languages
./proto.sh python   # bp_analyser/analyser_pb2*.py
./proto.sh dart     # healthpod/lib/features/bp/analyser/grpc/
```

Three calls:

| Call | Answers | What it does |
|------|---------|--------------|
| `Analyse(web_id, shared_file_count, requested_at)` | when the analysis is done | Runs one cycle for `web_id` and publishes the result to that Pod. |
| `Cancel(web_id, requested_at)` | immediately | Abandons the analysis running for `web_id`, at its next checkpoint. |
| `Status()` | immediately | Whether the service is up and ready, which Analyser Pod it acts for, and how many analyses it has in hand. |

`Analyse` is long-running by design — the reply *is* the result — so a client
sets a deadline generous enough to cover an analysis. The reply carries a
status rather than an error for anything the caller could act on: `COMPLETED`,
`CANCELLED`, `NO_DATA` (nothing shared that the analyser can read), `FAILED`.
A gRPC error status is reserved for the call itself being wrong — a missing
`web_id`, a bad token — because that is the only case where an app has nothing
to show a user.

`Status` exists to be called *before* sharing. Sharing is the expensive and
irreversible half of the round trip, and granting a dozen permissions only to
find that nothing is listening is the worst way round to learn it. It reads no
Pod and holds up no analysis.

### Cancelling

Cancelling has two halves, and only the second is this call:

- the app cancels its own `Analyse` call, which frees the app at once;
- the app sends `Cancel`, which tells the service to stop working.

Both are needed. gRPC gives a server no reliable notice of a cancelled unary
call part way through its handler, so a client that only dropped the call would
leave the service finishing an analysis nobody was waiting for. The service
does watch for it — `context.is_active()` is checked at each checkpoint — but
as a saving rather than a mechanism.

A `Cancel` naming a Pod with nothing running answers `NOTHING_RUNNING` and is
then forgotten. That matters: the marker files this replaced had to be
collected on *every* poll, running or not, precisely because one left lying
about would otherwise stop the next analysis — somebody else's — instead. A
request that cannot reach forward in time needs no expiry, no staleness rule
and no `cancel_max_age_seconds`.

A `Cancel` only ever looks at runs for the WebID it names, so a misdirected
request achieves nothing rather than stopping a stranger's analysis. The old
Pod channel could not manage that: the folder it used is publicly writable, so
anyone who could reach the Pod and knew a contributor's WebID could stop that
contributor's run.

### Exposing the port

Unlike the read-only HTTP API, this cannot sit on the loopback interface: the
caller is an app on somebody's laptop, so `grpc.host` defaults to `0.0.0.0`.
That is a deliberate exposure, and there are two ways to pay for it, neither
exclusive:

```yaml
grpc:
  token: 'a long random string'      # or $HEALTHPOD_ANALYSER_GRPC_TOKEN
  tls_cert_file: /etc/ssl/certs/analyser.pem
  tls_key_file: /etc/ssl/private/analyser.key
```

`token` requires every call to carry `authorization: Bearer <token>`, checked
by an interceptor so a method added later is guarded by default. Both TLS
files must be set together — half a certificate is refused at start-up rather
than quietly serving plaintext.

What the exposure is worth is modest but not nothing. An analysis publishes
only to the Pod that shared the data, so a stranger cannot read anybody's
readings by calling this; what they can do is set the analyser working, or stop
a run belonging to a WebID they know. A deployment on a closed network can
reasonably leave both settings empty. Anything reachable from the internet
should set both. A secret compiled into an app is not a secret from whoever
holds the app, so `token` keeps passers-by out rather than a determined user.

### Reaching it from a browser

A browser cannot open the HTTP/2 socket gRPC proper needs, so the web build of
HealthPod speaks **grpc-web**: the same messages over ordinary HTTP requests.
This service does not serve that format, so a deployment used from the browser
needs a translating proxy in front of it. Envoy's `grpc_web` filter is the
usual one; the app then points `Analyser.grpcHost` and `grpcPort` at the proxy
rather than at the service, and `grpcSecure` must be true, because a page
served over HTTPS will not call an insecure endpoint at all.

The desktop and mobile builds need none of this and talk to the service
directly. The web build compiles either way — see
`healthpod/lib/features/bp/analyser/channel.dart`.

## Preparing the Analyser Pod

The Analyser is an ordinary Pod with an ordinary account. It needs three
things: the Pod itself, the HealthPod folder structure inside it, and a set of
client credentials so the service can log in without a browser.

### 1. Create the account and the Pod

The simplest route is the server's own registration page: create an account,
then create a Pod named `Analyser` on it. The same can be done through the
account API, whose control URLs are all discoverable from `GET /.account/`
(`controls.account.create`, then `controls.password.create` to register the
login, then `controls.account.pod`) — the flow `solid_load_test.py` in
`solidpod/example/loadtest` automates.

The WebID that results is the address users will share with:

```
https://solid.dev.empwr.au/Analyser/profile/card#me
```

### 2. Initialise it with HealthPod

**This step matters.** The analyser reads keys that only HealthPod creates.

Log in to HealthPod (desktop or web) as the Analyser account **once**, and
complete the security key prompt. HealthPod then creates:

```
Analyser/healthpod/encryption/enc-keys.ttl    verification value, sealed RSA private key
Analyser/healthpod/encryption/ind-keys.ttl    keys of resources the Analyser owns
Analyser/healthpod/sharing/public-key.ttl     the RSA public key others seal with
Analyser/healthpod/shared/                    the sharing inbox (public read/write)
Analyser/healthpod/logs/permissions-log.ttl   the permission log
```

Record the security key you chose — the service needs it, and it cannot be
recovered from the server.

Until this is done, `grantPermission()` in the HealthPod app refuses to share
with the Analyser ("recipient Pod not initialised"), `run.sh check` reports
that `enc-keys.ttl` does not exist, and the service's `Status` call answers
that it is not ready — which is what the app checks before it shares
anything.

### 3. Issue client credentials

The Flutter apps log in interactively; a daemon cannot. CSS issues long-lived
client credentials for exactly this case:

```bash
SERVER=https://solid.dev.empwr.au
EMAIL=analyser@example.org
PASSWORD='the account password'

# a. Find the login control and log in to the account API.
LOGIN=$(curl -s "$SERVER/.account/" -H 'Accept: application/json' \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["controls"]["password"]["login"])')

TOKEN=$(curl -s -X POST "$LOGIN" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["authorization"])')

# b. Ask for credentials bound to the Analyser WebID.
CC=$(curl -s "$SERVER/.account/" -H 'Accept: application/json' \
  -H "Authorization: CSS-Account-Token $TOKEN" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["controls"]["account"]["clientCredentials"])')

curl -s -X POST "$CC" -H 'Content-Type: application/json' \
  -H "Authorization: CSS-Account-Token $TOKEN" \
  -d "{\"name\":\"bp-analyser\",\"webId\":\"$SERVER/Analyser/profile/card#me\"}"
```

The last call returns `{"id": "...", "secret": "..."}`. Those two values, plus
the security key from step 2, are all the service needs.

## Installing on the Solid server

The service is a plain Python application. It talks to the Solid server over
HTTPS like any other client, so it can run anywhere; the deployment documented
here keeps it on the same host, next to the server rather than inside it.

The deployment root is `/opt/solid/analyser`, a directory holding one project
per analyser and mirroring `healthpod/analyser/` in the repository. This
analyser is the `bp_analyser` project inside it, entirely self-contained: its
own virtual environment, configuration, results and service unit.

```bash
# As root, or with sudo.
useradd --system --home /opt/solid/analyser --shell /usr/sbin/nologin healthpod
mkdir -p /opt/solid/analyser

# Copy this project (healthpod/analyser/bp_analyser) into the root. Exclude
# `.venv`: a virtual environment built on a development machine has an
# interpreter symlinked to a path that does not exist on the server and
# binary wheels for the wrong platform, and it is the working copy most
# likely to have one lying about. `setup.sh` discards an unusable one, so
# copying it is a waste rather than a fault — but excluding it is quicker
# than transferring a few hundred megabytes to be deleted.
rsync -a --exclude='.venv' --exclude='__pycache__' --exclude='.DS_Store' \
      bp_analyser/ /opt/solid/analyser/bp_analyser/
chown -R healthpod:healthpod /opt/solid/analyser

# Create the virtual environment and install the dependencies. Invoking the
# script through bash rather than directly means a copy that arrived without
# the execute bit — over SFTP, or from an archive — still works; setup.sh
# restores the bit itself.
sudo -u healthpod bash /opt/solid/analyser/bp_analyser/setup.sh
```

The result:

```
/opt/solid/analyser/               the deployment root
└── bp_analyser/                   this project, and the working directory
    ├── bp_analyser/               the Python package
    ├── .venv/                     its virtual environment
    ├── config.yaml                its configuration
    └── var/                       its state, results and charts
```

`setup.sh` creates `.venv`, installs `requirements.txt` and copies
`config.example.yaml` to `config.yaml` if it is not already there. `run.sh`
changes to the project root before doing anything, so `python -m bp_analyser`
resolves whichever directory it is invoked from.

`setup.sh` tests an existing `.venv` by running its interpreter, and removes
it if that fails. `python3 -m venv` cannot heal such a directory itself: it
skips creating `bin/python3` when something is already linked there and then
fails trying to run it, reporting `[Errno 2] No such file or directory` for a
file that is sitting right in front of you as a broken symlink.

Adding a second analyser later means dropping another project beside this one;
nothing is shared between them but the root directory.

Requirements: Python 3.10 or newer, and outbound HTTPS to the Solid server.

### Updating a deployment

Copying a new version over an existing one leaves out two things that are not
part of the source: the virtual environment and `var/`. Re-running `setup.sh`
restores both, along with the execute bits that some transfers drop:

```bash
sudo systemctl stop healthpod-analyser
sudo rsync -a --exclude='.venv' --exclude='__pycache__' --exclude='.DS_Store' \
     bp_analyser/ /opt/solid/analyser/bp_analyser/
sudo chown -R healthpod:healthpod /opt/solid/analyser
sudo -u healthpod bash /opt/solid/analyser/bp_analyser/setup.sh
sudo systemctl start healthpod-analyser
```

Excluding `.venv` keeps the deployment's own environment rather than shipping
one built elsewhere over the top of it — which is the point, since the two are
never interchangeable.

`config.yaml` is never overwritten by `setup.sh`, so local settings and
secrets survive an update; compare it against `config.example.yaml` after a
version that adds settings. The service unit also creates `var/` before its
sandbox is built, so a deployment that has lost it starts anyway.

### Why not inside the Pod's storage

`/opt/solid/server` is the Community Solid Server's storage root: whatever sits
under it is a Pod resource, reachable at the matching URL. Putting the analyser
in, say, `/opt/solid/server/Analyser/analyser/` therefore makes `config.yaml`,
`var/` and `.venv` part of the Analyser Pod, and their privacy becomes a matter
of getting an ACL right — with the Pod's security key, the master key for
everything shared with the Analyser, on the wrong side of that bet. One
overwritten ACL, one Pod root shared too widely, and the key is a GET away.

`/opt/solid/analyser` is a sibling of the storage root, so none of it is served
at all. Confirm with the server itself; a 404 is what you want:

```bash
curl -sI https://solid.dev.empwr.au/analyser/ | head -1
```

**Migrating from inside the storage root.** If an earlier deployment lives
under `/opt/solid/server`, move it out, repoint the service and reissue the
client credentials — they sat in a file the server was mapping:

```bash
sudo systemctl stop healthpod-analyser
sudo mkdir -p /opt/solid/analyser
sudo mv /opt/solid/server/Analyser/analyser/bp_analyser /opt/solid/analyser/

# The protective ACL and the empty directory are no longer needed.
sudo rm -f /opt/solid/server/Analyser/analyser/.acl
sudo rmdir /opt/solid/server/Analyser/analyser

sudo chown -R healthpod:healthpod /opt/solid/analyser
sudo cp /opt/solid/analyser/bp_analyser/systemd/healthpod-analyser.service \
    /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl start healthpod-analyser
```

The virtual environment, `config.yaml` and `var/` move with the directory, and
nothing inside them records an absolute path: `run.sh` and the modules derive
every path from their own location.

## Configuration

Everything lives in `config.yaml`; `config.example.yaml` documents every key.
The essentials:

```yaml
analyser:
  web_id: https://solid.dev.empwr.au/Analyser/profile/card#me
  server_url: https://solid.dev.empwr.au   # derived from web_id when blank
  app_dir_name: healthpod
  security_key: ''                          # prefer the environment variable
  credentials:
    client_id: ''
    client_secret: ''
```

| Section | Key | Meaning |
|---------|-----|---------|
| `analyser` | `web_id` | The Analyser Pod. This is the address users share with. |
| | `app_dir_name` | The application folder in every Pod. `healthpod` for HealthPod. |
| `data` | `path_fragments` | A shared resource is analysed when its URL contains one of these. Default `/data/blood_pressure/`. |
| `analysis` | `minimum_observations` | Pods below this are reported but left out of the cohort average. |
| | `window_days` | Only consider recent readings. Blank means all history. |
| `sharing` | `enabled` | Turn the write-back off for a read-only trial run. |
| | `results_dir` | Folder in the Analyser Pod holding published results. |
| | `share_cohort_average` | Also give the caller the average of averages. |
| | `encrypt_results` | Encrypt published results, as HealthPod does. |
| `grpc` | `host`, `port` | Where the app calls. `0.0.0.0:50051` by default; see [Exposing the port](#exposing-the-port). |
| | `token` | Shared secret every caller must present. Empty means none. |
| | `tls_cert_file`, `tls_key_file` | Server-side TLS, as PEM files. Both or neither. |
| | `max_workers` | Calls served at once. Analyses are serialised regardless. |
| | `analysis_timeout_seconds` | How long one analysis may run before it is abandoned (default 300). |
| `output` | `state_dir`, `results_dir`, `charts_dir` | Local paths, relative to `config.yaml`. |
| `api` | `enabled`, `host`, `port`, `cors_origins` | The read-only front-end interface. |

Secrets can come from the environment instead of the file, which is what the
systemd unit does:

```
HEALTHPOD_ANALYSER_SECURITY_KEY
HEALTHPOD_ANALYSER_CLIENT_ID
HEALTHPOD_ANALYSER_CLIENT_SECRET
HEALTHPOD_ANALYSER_GRPC_TOKEN
HEALTHPOD_ANALYSER_CONFIG        path to config.yaml, if not ./config.yaml
```

Under systemd the environment file is the natural home: the secrets stay out
of the deployment directory, and so out of any copy or backup of it. Keeping
them in `config.yaml` is reasonable too now that the directory is not part of
any Pod — but `chmod 600 config.yaml` either way. The analyser warns at startup
when a file holding secrets is readable by other accounts.

## Running it

```bash
./run.sh check          # verify credentials, keys and what has been shared
./run.sh grpc           # serve the app (this is what systemd runs)
./run.sh serve          # the read-only front-end API
./run.sh run-once       # one cycle for every contributing Pod, then exit
./run.sh analyse WEBID  # make the call the app makes, and print the reply
./run.sh cancel WEBID   # ask it to abandon the analysis for that Pod
./run.sh status         # ask a running server what it is doing
./run.sh show-config    # the effective configuration, with secrets redacted
./run.sh test           # the offline test suite
```

`analyse`, `cancel` and `status` are clients of a running `grpc` server rather
than of the Pod, so they answer only while one is running — which is the point
of them. With the watcher gone there is no other way to ask a live analyser for
anything, and being able to make the exact call the app makes is what turns
"the app says it is slow" into an answer.

Always start with `check`. It logs in, unlocks the Pod, and prints everything
that has been shared, without writing anything:

```
Configuration:      /opt/solid/analyser/bp_analyser/config.yaml
Analyser WebID:     https://solid.dev.empwr.au/Analyser/profile/card#me
Server:             https://solid.dev.empwr.au
Application folder: healthpod
Login:              ok (client credentials, DPoP bound)
Pod unlocked:       ok (key derivation version 2)
Shared with us:     3 resource(s)
  - [file] https://solid.dev.empwr.au/alice/healthpod/data/blood_pressure/bp_2026-08-19.json.enc.ttl (read)
  ...
Contributing Pods:  2
  - solid.dev.empwr.au-alice: 2 file(s)
  - solid.dev.empwr.au-bob: 4 file(s)
gRPC interface:     0.0.0.0:50051
Charts:             available
Results directory:  /opt/solid/analyser/bp_analyser/var/results
```

Then, with a server running, make the call the app makes:

```
$ ./run.sh analyse https://solid.dev.empwr.au/alice/profile/card#me
Status:             ANALYSE_STATUS_COMPLETED
Run:                20260908T101500Z
Generated at:       2026-09-08T10:15:00+00:00
Observations:       12
Files read:         12 (0 skipped)
Contributing Pods:  2
Published:          yes
Result:             https://solid.dev.empwr.au/Analyser/healthpod/data/analyser/solid.dev.empwr.au-alice/bp-average.json.enc.ttl
```

Exit codes: `0` success, `2` configuration, `3` keys (usually the wrong
security key), `4` the Solid server, or a gRPC call that could not be made.

### Running continuously under systemd

`./run.sh grpc` in a terminal is for trying things out: it dies with the
session. Rather than keeping it alive in `screen` or `tmux` — which survives
the logout but not a crash, a reboot, or an out-of-memory kill — run it as a
service. The units below add automatic restart, start-on-boot, journal
logging, and a filesystem sandbox that lets the process write only to `var/`.

From the project root (/opt/solid/analyser/bp_analyser):

```bash
sudo cp systemd/healthpod-analyser.service /etc/systemd/system/
sudo cp systemd/healthpod-analyser.env /etc/healthpod-analyser.env
sudo chmod 600 /etc/healthpod-analyser.env
sudo editor /etc/healthpod-analyser.env      # fill in the secrets

# The unit runs as healthpod:healthpod, the unprivileged account created
# during installation. Adjust User= and Group= if you use another one.
sudo editor /etc/systemd/system/healthpod-analyser.service

# That account must own the tree, or the service cannot write var/. It matters
# most when the virtual environment was created as root.
sudo chown -R healthpod:healthpod /opt/solid/analyser

sudo systemctl daemon-reload
sudo systemctl enable --now healthpod-analyser

# Confirm it is up, then watch it work.
systemctl status healthpod-analyser --no-pager
journalctl -u healthpod-analyser -f
```

A healthy start logs `ready`, then one `serving gRPC on …` line, and then
nothing at all until an app calls. If the service stops immediately with status
2, a secret is missing from `/etc/healthpod-analyser.env`; `systemctl status`
prints the same one-line reason `./run.sh check` would.

**Open the port.** The app is not on this host, so the firewall has to let it
in — and this is the step most easily forgotten, because everything on the
server looks healthy without it:

```bash
sudo ufw allow 50051/tcp comment 'healthpod analyser'
```

Confirm from the machine the app runs on, not from the server:

```bash
nc -zv solid.dev.empwr.au 50051
```

The service:

- **does nothing until asked.** No poll, no timer, no periodic rescan. An idle
  analyser makes no requests of the Solid server at all;
- **logs in and unlocks the Pod at start-up**, so the first Analyse call is no
  slower than the rest. A failure there is recorded rather than fatal — the
  Analyser Pod may not be initialised yet, and that resolves — and `Status`
  reports it until the next call succeeds;
- **serialises analyses.** One Solid connection and one set of unlocked keys
  are shared by every call, so a second Analyse waits for the first. It can be
  cancelled while it waits, which is the case worth having: a user queued
  behind somebody else's analysis should not have to wait it out to give up;
- **abandons the cycle in hand** when a Cancel arrives, at the next point
  between two steps where stopping is safe. Nothing is left half written;
- **recovers from transient errors** by dropping the connection so the next
  call logs in afresh. An expired or revoked token is the commonest cause of a
  hard failure, and this is what fixes it without a restart;
- **refuses to start on a configuration error** — a missing credential is
  checked before the port is opened, reported in one line, and exits with
  status 2, which `RestartPreventExitStatus=2` in the unit turns into a stop
  rather than a restart loop;
- **finishes the analysis in hand** when systemd asks it to stop, within the
  30 second grace period.

To serve the read-only API as well:

```bash
sudo cp systemd/healthpod-analyser-api.service /etc/systemd/system/
sudo systemctl enable --now healthpod-analyser-api
```

The API process holds no credentials — it only reads what the analysing
process has already written to `var/`.

### Recomputing without an app

`run-once` analyses for everybody, as a cycle used to: no caller means no focus
Pod, so every contributor gets a chart and a result. It is idempotent and safe
to schedule, for a deployment that wants the figures kept warm regardless of
who has pressed anything:

```
0 * * * * /opt/solid/analyser/bp_analyser/run.sh run-once >> /opt/solid/analyser/bp_analyser/var/cron.log 2>&1
```

It is a separate process from the server, with its own login, and it cannot be
cancelled — a cancellation is a call to a running server, and this is not one.

## How a user asks for an analysis

HealthPod has an **Analyse** button in the top right of the blood pressure
chart (`Icons.analytics_outlined`, beside the information tooltips). One press
covers the whole round trip:

1. the app counts the readings and asks the user to confirm, naming the
   Analyser's WebID and what it will be allowed to do — read, nothing else;
2. it calls `Status`, to be sure the analyser is up before anything is shared
   with it, and that it is the analyser this app shares with;
3. it grants read access to each reading in turn;
4. it calls `Analyse`, naming itself, and waits for the reply;
5. it reads the result the analyser published, saves it to the user's own Pod,
   and shows the chart in a dialogue.

Step 2 is the one that looks out of place and is not. Sharing is the expensive
and irreversible half — a dozen ACL updates and a dozen sealed keys — and
granting all of it only to find that nothing is listening is the worst way
round to learn it. The check costs a few milliseconds against a working
deployment.

The button is disabled for the whole of that round trip and comes back to life
when the chart appears, so a second press cannot start a competing run.

While it runs the button is a progress ring. Pointing at the ring turns it
into a cancel button; the ring is pressable without a hover as well, since a
touch screen never reports one. Readings already shared stay shared —
withdrawing them is a separate decision, made in the file browser, and undoing
it silently would be a surprise.

### How the cancellation reaches the analyser

On the same connection the analysis went out on, which is the whole of the
change. See [Cancelling](#cancelling) for what the service does with it.

From the app's side, pressing cancel does three things at once:

- it stops the round trip at its next step, which is what frees the app during
  the sharing;
- it drops the `Analyse` call, which is what frees the app during the
  analysis;
- it sends `Cancel`, which is the half the user is actually asking about.

The reply to that third call is what the app colours its answer by: green when
the analyser says it has stopped or had nothing to stop, red when the request
could not be delivered. Both come back in milliseconds. The app stops waiting
either way, so a red message means the analysis may still be running on the
server rather than that the user is stuck.

That is worth comparing with what it replaced. The old channel wrote a marker
file into the Analyser Pod's publicly writable `shared/` container and then
watched for the analyser to delete it, which was the only acknowledgement
available. An analyser part way through a cycle answered in a few seconds; an
idle one only looked once per poll, so the app spun for up to thirty and then
gave up after forty. The delete was load-bearing — a change that stopped
removing collected markers would have left the app reporting success for
analyses that carried on — and the container being publicly writable meant
anyone who could reach the Pod and knew a contributor's WebID could stop that
contributor's analysis. None of that is true now: nothing is written, nothing
is polled, the answer is authoritative because it comes from the process doing
the work, and a request can only ever affect the caller's own run.

### Collecting the result

The app reads the result straight from its address rather than searching for
it, because the analyser publishes to a predictable place:

    <analyser>/healthpod/data/analyser/<pod-id>/bp-average.json.enc.ttl

The `Analyse` reply says when the analyser made the result, and the app checks
that against what it reads. A document carrying a different timestamp is the
previous run's, still at the address because the new write has not become
visible yet, so the app tries again — three attempts, a second and a half
apart. Comparing against what the analyser said, rather than against the
current time, keeps this correct however far apart the device's clock and the
server's are, which is routinely by seconds.

This is where the old design spent most of its time. With no way of knowing
when the analyser had finished, the app noted the timestamp of whatever was
already published *before* it shared anything, then read the address every
three seconds for up to ninety, looking for something different. It also had
to guard against a subtler thing: another Pod's share could set a run going
that finished after this user pressed **Analyse** but before their readings
were all granted, so a new timestamp alone was not proof of a complete
analysis, and the app compared `pod.files_read` plus `pod.files_skipped`
against the number of readings it had shared and kept waiting when it saw
fewer.

That comparison survives, because the situation it guards against has not
quite gone: analyses are serialised, so a run of the caller's own can still
begin while a grant is in flight. But it is now a remark rather than a wait —
the `Analyse` reply carries `files_read` and `files_skipped`, the app shows the
result and says `covered 9 of your 12 observations` alongside it, and the user
can bring the rest in by analysing again.

Readings recorded after an analysis are not included automatically: each is a
new resource with a new key, so the user presses **Analyse** again to bring
them in. The tooltip on the button says so.

### Sharing by hand

The same thing can be done through the ordinary sharing dialogue, which is
useful for testing without the app's button:

1. open the file browser and go to `healthpod/data/blood_pressure`;
2. select the readings to contribute (or the folder itself);
3. choose **Share**, pick **Individual** as the recipient type, and enter
   `https://solid.dev.empwr.au/Analyser/profile/card#me`;
4. tick **Read**, and confirm.

Sharing individual files is the reliable choice. Sharing the folder works only
when the readings inherit the folder's encryption key; see
[Known limitations](#known-limitations).

To stop contributing, the user revokes the share in HealthPod. The analyser
stops being able to read those files at the next cycle, and the Pod drops out
of the cohort.

## What the caller receives back

Two documents are published into the Analyser Pod and shared out:

```
<analyser>/healthpod/data/analyser/<pod-id>/bp-average.json.enc.ttl        → the caller
<analyser>/healthpod/data/analyser/cohort/bp-cohort-average.json.enc.ttl   → the caller
```

Both go to the Pod that asked, and only to it. Every contributing Pod is still
*read* — the cohort figure is the average of their averages — but the writing
back is the caller's alone. That is most of why an analysis now takes seconds
rather than however long it took to chart and publish for everybody who had
ever shared. (`run-once` on the command line has no caller, and does publish
to every contributor; see
[Recomputing without an app](#recomputing-without-an-app).)

Each is encrypted with its own key, exactly as HealthPod encrypts its files,
and the key is handed to the recipient through their `shared-keys.ttl`. A line
in the recipient's permission log makes it appear in HealthPod's list of
resources shared with them.

The per-Pod document carries the figures and the chart together, so an app
gets both from a single read:

```json
{
  "schema_version": 1,
  "kind": "pod-average",
  "generated_at": "2026-08-19T10:15:00+00:00",
  "analyser_web_id": "https://solid.dev.empwr.au/Analyser/profile/card#me",
  "average": {"systolic": 125.0, "diastolic": 85.0, "heart_rate": 65.0},
  "pod": { "observation_count": 2, "measures": { "...": "min, max, standard deviation" } },
  "cohort": {
    "pod_count": 2,
    "average_of_averages": {"systolic": 135.0, "diastolic": 91.2, "heart_rate": 72.5},
    "pooled_average": {"systolic": 135.0, "diastolic": 91.2, "heart_rate": 72.5}
  },
  "units": {"systolic": "mm Hg", "diastolic": "mm Hg", "heart_rate": "bpm"},
  "chart": {"format": "png", "encoding": "base64", "data": "iVBORw0KGgo..."}
}
```

`files_read` and `files_skipped` inside `pod` are not only diagnostics: they
are how a reader knows whether the result covers what it just shared. Every
shared file the analyser found was either read or skipped, so their sum is the
number of files it had in view, and comparing it against the number of
readings shared says how much of the Pod the result covers. The same two
figures come back in the `Analyse` reply, so an app has the answer before it
reads anything; HealthPod shows the result and says `covered 9 of your 12
observations` beside it when the two do not agree.

`chart` holds that Pod's own chart: its readings over time as three lines —
systolic, diastolic and heart rate — with its own averages dashed across them
and the cohort averages dotted. It is base64-encoded PNG because Solid sharing
carries text, which means the app needs no second channel and no extra
credentials to fetch the picture. The field is absent when charts are switched
off or matplotlib is missing, so a reader must tolerate that.

The cohort document is the same without the `pod`, `average` and `chart`
sections. No Pod ever receives another Pod's readings, averages or WebID.

## The results document

`var/results/latest.json` is the contract between the analyser and anything
that displays its output. Every run also lands in `var/results/run-<id>.json`.

```json
{
  "schema_version": 1,
  "run_id": "20260819T101500Z",
  "generated_at": "2026-08-19T10:15:00+00:00",
  "requested_by": "https://solid.dev.empwr.au/alice/profile/card#me",
  "analyser": {"web_id": "...", "app_dir_name": "healthpod", "server_url": "..."},
  "analysis": {"minimum_observations": 1, "window_days": null},
  "cohort": {
    "pod_count": 2,
    "included_pod_count": 2,
    "observation_count": 4,
    "average_of_averages": {"systolic": 135.0, "diastolic": 91.2, "heart_rate": 75.0},
    "pooled_average": {"systolic": 135.0, "diastolic": 91.2, "heart_rate": 75.0},
    "spread_of_averages": {"systolic": 10.0, "diastolic": 6.2, "heart_rate": 5.0}
  },
  "pods": [
    {
      "pod_id": "solid.dev.empwr.au-alice",
      "web_id": "https://solid.dev.empwr.au/alice/profile/card#me",
      "pod_root": "https://solid.dev.empwr.au/alice/",
      "observation_count": 2,
      "files_read": 2,
      "files_skipped": 0,
      "included_in_cohort": true,
      "first_observation": "2026-08-10T09:00:00+00:00",
      "last_observation": "2026-08-11T09:00:00+00:00",
      "measures": {
        "systolic": {"average": 125.0, "minimum": 120.0, "maximum": 130.0,
                     "standard_deviation": 5.0, "count": 2},
        "diastolic": {"...": "..."},
        "heart_rate": {"...": "..."}
      },
      "notes": []
    }
  ],
  "charts": {"pods": {"solid.dev.empwr.au-alice": "solid.dev.empwr.au-alice.png"}},
  "sharing": {"enabled": true, "published": [
    {"kind": "pod-average", "pod_id": "solid.dev.empwr.au-alice",
     "resource_url": "https://.../bp-average.json.enc.ttl",
     "recipients": ["https://solid.dev.empwr.au/alice/profile/card#me"], "failures": {}}
  ]},
  "warnings": []
}
```

`pod_id` is the stable, URL-safe form of the WebID that solidpod itself uses
(`server-host-podname`), so the same Pod carries the same identifier in the
apps, in the charts and in the API.

`requested_by` names the Pod that asked for the run, and is `null` for a
`run-once` from the command line. It is also what says why `pods` may list
more Pods than `sharing.published` and `charts.pods` do: everybody was read,
one Pod was written to.

**Two cohort figures, deliberately.** `average_of_averages` weights every Pod
equally and is the figure shared back; `pooled_average` weights every reading
equally and is reported for context. `spread_of_averages` is the population
standard deviation of the per-Pod averages.

`warnings` collects anything skipped — a file that could not be decrypted, a
Pod that revoked access mid-run — so nothing fails silently.

## The front-end API

`./run.sh serve` (or the API systemd unit) exposes the results over HTTP. It
only reads local files, so it can face a front end without any Pod access.

| Method | Path | Returns |
|--------|------|---------|
| GET | `/health` | Liveness and a summary of the last run. |
| GET | `/api/summary` | The whole latest results document. |
| GET | `/api/cohort` | The cohort figures only. |
| GET | `/api/pods` | One entry per contributing Pod. |
| GET | `/api/pods/{pod_id}` | One Pod's averages plus the cohort figures. |
| GET | `/api/pods/{pod_id}/chart.png` | That Pod's readings over time, with both sets of averages. |
| GET | `/api/runs` | Stored run identifiers, newest first. |
| GET | `/api/runs/{run_id}` | One stored run in full. |
| GET | `/api/status` | Whether a cycle is running, and how the last one ended. |

```bash
curl -s http://127.0.0.1:8088/api/cohort | python3 -m json.tool
curl -s -o chart.png http://127.0.0.1:8088/api/pods/solid.dev.empwr.au-alice/chart.png
curl -s http://127.0.0.1:8088/api/status | python3 -m json.tool
```

**Read-only in full, and there is nothing here to guard.** This once had
`POST /api/refresh` and `POST /api/cancel`, each of which wrote a marker file
into the state directory for the watcher to find on its next poll. There is no
watcher, so there is nothing to find them: starting an analysis and cancelling
one are gRPC calls now, answered by the process doing the work. `api.token`
went with them.

`/api/status` reads the marker the analysing process writes, so it is also left
behind by a process killed mid-cycle; treat a long-standing entry as the last
run attempted rather than one still going. An app that wants a live answer
calls gRPC `Status`, which is served from that process's own memory.

Interactive documentation is at `/docs`, generated by FastAPI.

Charts are PNG files rendered with matplotlib into `var/charts/`, and the same
image is embedded in the result the Pod receives. One is drawn per run rather
than one per Pod — the caller's — so `var/charts/` accumulates the most recent
chart for each Pod that has asked, and the file for a Pod that has not asked
recently belongs to an older run than `latest.json` does. Set
`output.render_charts: false` to skip them; the JSON is unaffected. A front end
that would rather draw its own charts has everything it needs in
`/api/summary`.

**What the chart shows.** One picture for the caller: that Pod's systolic, diastolic
and heart rate readings plotted over time, with six reference lines across
them — the Pod's own average for each measure (dashed, labelled on the right)
and the average across every contributing Pod (dotted, labelled on the left).
The three measures share one axis: pressure is in millimetres of mercury and
pulse in beats per minute, but the ranges overlap closely enough for a single
scale, and the axis says so. A second y-axis would invite the reader to
compare two scales as though they were one.

**Extending it.** The reserved shape is: the cycle writes a field into the
results document, and a route in `bp_analyser/api.py` serves it. Adding a
per-Pod time series, for example, means extending `PodSummary.to_dict()` and
adding `/api/pods/{pod_id}/series`; nothing else changes.

## Privacy and security

- **Nothing is read that was not shared.** The analyser can only decrypt a file
  whose key its owner sealed for the Analyser's public key. Revoking the share
  in HealthPod removes both the key and the access.
- **No raw readings leave the Analyser.** A Pod receives its own average and
  the cohort aggregate — never another participant's readings, averages or
  WebID. The cohort document names no one.
- **Results are encrypted at rest** in the Analyser Pod, with a fresh key per
  document, and shared through the same key-exchange the apps use.
- **The Analyser's security key unlocks every share it holds.** Keep it in
  `/etc/healthpod-analyser.env` with mode 600, or in whatever secret store the
  host provides — never in a repository.
- **Local results are plaintext JSON** under `var/`, so that directory deserves
  the same care as any other health data on the host. It contains averages and
  Pod WebIDs, not individual readings.
- **The deployment lives outside the storage root** (`/opt/solid/analyser`,
  beside `/opt/solid/server` rather than under it), so `config.yaml`, `var/`
  and `.venv` are ordinary files rather than Pod resources — see
  [Why not inside the Pod's storage](#why-not-inside-the-pods-storage).
- **The gRPC port is the deliberate exposure.** It cannot be on the loopback
  interface, because the caller is an app on somebody's laptop. Set
  `grpc.token` and serve TLS on anything reachable from outside a private
  network — see [Exposing the port](#exposing-the-port) for what the exposure
  is actually worth, which is an unwanted analysis rather than disclosure: a
  run only ever publishes to the Pod that shared the data.
- **A cancellation can only stop the caller's own analysis.** The request
  names a WebID and only runs for that WebID are looked at. The channel this
  replaced could not manage that — it used the one container solidpod leaves
  publicly writable, so anyone who could reach the Analyser Pod and knew a
  contributor's WebID could stop that contributor's run.
- **The HTTP API is read-only and holds no credentials.** Nothing there
  writes, so there is nothing to guard. Bind it to `127.0.0.1` and put it
  behind the same reverse proxy and TLS as the rest of the deployment; set
  `api.cors_origins` to the front end's origin rather than `*`.
- **Writing into another Pod.** Handing over a key writes into the recipient's
  `healthpod/shared/shared-keys.ttl` and appends to their permission log. This
  is how solidpod's own sharing works: a Pod initialised by solidpod grants
  public write on `shared/` and public append on the log precisely so other
  agents can deliver keys. Nothing else in the recipient's Pod is touched.

## Troubleshooting

| Symptom | Cause and remedy |
|---------|------------------|
| `setup.sh: command not found`, or `unable to execute setup.sh: Permission denied` | The copy lost the execute bit, or the service account cannot traverse the directory. Run `bash setup.sh` instead, and check `namei -l /opt/solid/analyser/bp_analyser/setup.sh` — every directory on the path needs `x` for that account. |
| `Error: [Errno 2] No such file or directory: '.../.venv/bin/python3'` from `setup.sh` | A `.venv` built on another machine came with the copy: its interpreter is a symlink to a path that does not exist here. Current versions of `setup.sh` discard such a venv, so this means an older one is installed — `rm -rf .venv` and run it again. Copy with `rsync -a --exclude='.venv'` to avoid it. |
| `ModuleNotFoundError` for a package that `pip list` shows as installed | The same cause one step later: a venv from another platform, whose site-packages hold wheels built for it. `rm -rf .venv && bash setup.sh`. |
| `WARNING ... holds secrets ... and is readable by other accounts (mode 644)` | Exactly what it says: `chmod 600 config.yaml`, or move the secrets to `/etc/healthpod-analyser.env`. |
| `Configuration error: missing credentials: ...` and the process exits with status 2 | Expected before the secrets are in place: fill in `config.yaml`, or `/etc/healthpod-analyser.env` under systemd, then `./run.sh check`. |
| `Key error: ... enc-keys.ttl does not exist` | The Analyser Pod has never been opened in HealthPod. Do step 2 of [Preparing the Analyser Pod](#preparing-the-analyser-pod). |
| `the configured security key does not match` | Wrong security key, or the Pod was re-initialised with a new one. Correct `HEALTHPOD_ANALYSER_SECURITY_KEY`. |
| `login failed: HTTP 401` | The client credentials were revoked or belong to another account. Issue a new pair (step 3). |
| `Shared with us: 0 resource(s)` | Nobody has shared yet, or they shared with a different WebID. Check the exact WebID in the share dialogue, including `#me`. |
| The app says the recipient Pod is not initialised | Same as the first row: HealthPod refuses to share with a Pod that has no key structure. |
| `Contributing Pods: 0` although resources are listed | The shared paths do not match `data.path_fragments`. Widen it, or set it to `[]` to accept everything shared. |
| `no key has been shared for this resource` in the warnings | A folder was shared but its files carry their own keys. Ask the owner to share the files, not the folder. See [Known limitations](#known-limitations). |
| Nobody can share with the Analyser any more, and HealthPod reports the recipient Pod as not initialised | Something has tightened the Analyser Pod's ACLs: `healthpod/sharing/public-key.ttl` must stay publicly readable and `healthpod/shared/` publicly writable, or no Pod can hand over a key. Check with `curl -sI https://solid.dev.empwr.au/Analyser/healthpod/sharing/public-key.ttl`, which must answer 200. |
| The app reports `Invalid or corrupted pad block` for a result it can fetch | The content was decrypted with the wrong key. A resource keeps one key for its whole life precisely so this cannot happen — readers cache the key they were handed and only ask again when they hold none — so suspect a reader holding a key from before that rule existed: restart the app. |
| The app reports `No encryption key found` for a result it can fetch | The resource key never reached that Pod's `healthpod/shared/shared-keys.ttl`. Every delivery is now read back and confirmed, so the reason appears as `did not receive the key` in `warnings` and in the journal. Re-running the analysis delivers it again. |
| Results computed, `failures` non-empty | The recipient Pod has no `public-key.ttl`, or the analyser cannot write to their `shared/`. That Pod has not been initialised for the `healthpod` application. |
| Charts missing | matplotlib is not installed, or `output.render_charts` is false. |
| `403` writing into the Analyser Pod | The client credentials are bound to a different WebID than `analyser.web_id`. |

Then the ones that belong to the gRPC interface:

| Symptom | Cause and remedy |
|---------|------------------|
| The app says the Analyser is not answering, and `./run.sh status` on the host works | The port is not open from outside. `sudo ufw allow 50051/tcp`, then confirm from the machine the app runs on: `nc -zv solid.dev.empwr.au 50051`. |
| `./run.sh status` says `nothing is listening on 127.0.0.1:50051` | No server is running: `systemctl status healthpod-analyser`. This is also what a server bound to another address answers — check `grpc.host` and `grpc.port` in `show-config`. |
| `./run.sh status` says `the analyser rejected the token` | `grpc.token` differs between the two, or the app's `Analyser.grpcToken` differs from the service's. Both must match exactly. |
| The app says the Analyser is not ready, and gives a reason | The service is up but cannot unlock its Pod. The reason is the same one `./run.sh check` would give; it clears itself once fixed, without a restart. |
| The app says the service acts for a different Analyser Pod | `Analyser.webId` in the app and `analyser.web_id` in `config.yaml` disagree. Readings would be shared with one Pod and analysed by another, which is why this is refused before anything is shared. |
| `ANALYSE_STATUS_NO_DATA` for a Pod that has shared readings | The analyser can see them and cannot read them, or they do not match `data.path_fragments`. `./run.sh check` lists exactly what it can see. |
| The analysis answers `FAILED` with `could not reach the Solid server` | Usually an expired or revoked token. The connection is dropped on such a failure, so the next call logs in afresh: try again before restarting anything. |
| An analysis takes minutes, or answers `the analysis took too long` | Another analysis is queued ahead of it — they are serialised — or a Pod read is hanging. `./run.sh status` reports `Analyses in hand`. |
| A browser build cannot reach the service at all | Expected: a browser speaks grpc-web, which this does not serve. See [Reaching it from a browser](#reaching-it-from-a-browser). |
| `TypeError` or a version complaint from `analyser_pb2.py` | The installed `protobuf` or `grpcio` is older than the committed bindings need. `pip install -r requirements.txt`; the floors there are what the bindings were generated against. |

Raise the detail with `./run.sh --verbose check`, and watch a live service with
`journalctl -u healthpod-analyser -f`. A live analysis logs one line as it
starts, one per Pod as it reads, and one as it finishes.

### When the service will not start

`Job for healthpod-analyser.service failed because of unavailable resources or
another system error` means systemd could not prepare the process — it never
ran, so nothing appears in the analyser's own log. The status code names the
cause:

```bash
systemctl status healthpod-analyser.service -l --no-pager
journalctl -xeu healthpod-analyser.service | tail -30
```

| Status | Cause | Remedy |
|--------|-------|--------|
| `226/NAMESPACE` | `ReadWritePaths` points at `var/`, which does not exist — systemd builds the mount namespace before the process starts, and a deployment copied from source has no `var/`. Current units create it first, so this means an older unit is installed. | Copy the unit again from `systemd/`, `systemctl daemon-reload`, or create the directory by hand: `sudo -u healthpod mkdir -p /opt/solid/analyser/bp_analyser/var`. |
| `217/USER` | The `healthpod` account does not exist. | `sudo useradd --system --home /opt/solid/analyser --shell /usr/sbin/nologin healthpod`, or point `User=`/`Group=` at an account that does. |
| `203/EXEC` | `.venv/bin/python` is missing or not executable by the service account. | Run `setup.sh`, then `sudo chown -R healthpod:healthpod /opt/solid/analyser`. |
| `200/CHDIR` | `WorkingDirectory` does not exist, or the account cannot traverse into it. | Check `namei -l /opt/solid/analyser/bp_analyser`; every directory on the path needs `x`. |
| `Failed to load environment files` | `/etc/healthpod-analyser.env` is absent. | Copy `systemd/healthpod-analyser.env` there, or leave it out: the unit marks the file optional, so secrets in `config.yaml` work too. |

A quick way to confirm the sandbox and the account before involving systemd:

```bash
sudo -u healthpod /opt/solid/analyser/bp_analyser/.venv/bin/python --version
sudo -u healthpod touch /opt/solid/analyser/bp_analyser/var/.write-test && echo writable
```

### Checking a security key offline

`./run.sh check` needs all three secrets before it can tell you whether the
security key is right, which is awkward when the key is the one in doubt. On a
host with access to the Pod's storage the key can be checked on its own,
against the verification value the Pod itself stores — no credentials, no
network:

```bash
cd /opt/solid/analyser/bp_analyser
./.venv/bin/python - /opt/solid/server/Analyser/healthpod/encryption/enc-keys.ttl <<'EOF'
import base64, getpass, pathlib, sys
from bp_analyser import crypto, turtle

path = pathlib.Path(sys.argv[1])
record = next(
    fields for fields in turtle.triple_map(path.read_text()).values()
    if 'https://solidcommunity.au/predicates/terms#encKey' in fields)


def value(name):
    return turtle.single(
        record.get('https://solidcommunity.au/predicates/terms#' + name))


salt = value('salt')
print('key derivation version:', value('keyVersion') or '1 (legacy, no salt)')

candidate = getpass.getpass('Security key: ')
_, derived = (crypto.derive_keys_v2(candidate, base64.b64decode(salt))
              if salt else crypto.derive_keys_v1(candidate))
print('MATCH' if crypto.verification_matches(value('encKey'), derived)
      else 'NO MATCH')
EOF
```

The file itself is worth a look first: if
`Analyser/healthpod/encryption/enc-keys.ttl` is absent, the Analyser Pod has
never been initialised in HealthPod and no security key exists yet. The
Community Solid Server may store it under a `$.ttl` suffix, so list the
directory rather than assuming the name.

## Development

`healthpod/analyser/` holds one project per analyser; this is the blood
pressure one. The project root carries the scripts, the configuration and the
tests; the code lives in the `bp_analyser` package inside it.

```
healthpod/analyser/
└── bp_analyser/                     the project root, and the working directory
    ├── bp_analyser/                 the Python package
    │   ├── __main__.py              the command line
    │   ├── analyser.proto           the contract with the app
    │   ├── analyser_pb2.py          generated from it; do not edit
    │   ├── analyser_pb2_grpc.py     generated from it; do not edit
    │   ├── grpc_server.py           the three handlers, and the server
    │   ├── grpc_client.py           the analyse/cancel/status commands
    │   ├── service.py               the analysis cycle
    │   ├── config.py                YAML configuration and environment overrides
    │   ├── crypto.py                solidpod-compatible cryptography
    │   ├── pod_paths.py             Pod URL arithmetic
    │   ├── turtle.py                reading and writing the Pod's turtle documents
    │   ├── solid_client.py          DPoP-authenticated HTTP client
    │   ├── keys.py                  the Analyser's keys and its sharing inbox
    │   ├── discovery.py             shared resources grouped per Pod
    │   ├── bp_data.py               decrypting and parsing readings
    │   ├── statistics.py            per-Pod averages and the cohort figures
    │   ├── publisher.py             publishing results and sharing them back
    │   ├── store.py                 local state, results and run history
    │   ├── charts.py                optional PNG charts
    │   ├── api.py                   the read-only front-end API
    │   └── logs.py                  logging set-up
    ├── tests/                       unit tests and an end-to-end pipeline test
    ├── systemd/                     service units and the environment file
    ├── README.md
    ├── config.example.yaml
    ├── config.yaml                  yours, ignored by git
    ├── proto.sh                     regenerate the bindings, both languages
    ├── requirements.txt
    ├── setup.sh
    ├── run.sh
    └── var/                         created at run time: state, results, charts
```

The app's half of the contract lives at
`healthpod/lib/features/bp/analyser/`: `analyser_client.dart` wraps the three
calls, `channel.dart` picks a channel for the platform, and `grpc/` holds the
generated Dart. Both sets of bindings come from `bp_analyser/analyser.proto`
via `proto.sh`, and both are committed, so a change to the contract means
running `./proto.sh` and committing what it produces — in one commit, or the
two languages disagree.

Run the tests — they need no server and no network:

```bash
./run.sh test
```

Or directly, from the project root:

```bash
./.venv/bin/python -m unittest discover -s tests -t .
```

`tests/test_pipeline.py` builds an in-memory Pod server holding two
contributors — one who shared individual files, one who shared a folder — and
drives the real code against it three ways: a full cycle, a cycle asked for by
one caller, and the gRPC handlers themselves. It therefore exercises the whole
protocol, including the parts that write into somebody else's Pod.

The handlers are called directly rather than over a channel, with a stand-in
for the two things they ask of a gRPC context. One test does start a real
analysis on one thread and cancel it from another, holding the cycle inside a
Pod read until the Cancel has been answered: cancelling mid-cycle is the
behaviour this whole change exists for, and testing it against a scheduler
race would be testing the scheduler.

On the app's side, `test/features/bp/analyser/analyser_client_test.dart`
stands a real gRPC server up on a loopback port and drives the Dart client
against it, including the cases that matter most — the analyser not running,
the token refused, the user cancelling part way through — none of which can be
exercised by mocking the stub.

`tests/test_crypto.py` checks the cryptography against vectors produced by
solidpod's own Dart libraries (`package:cryptography` for Argon2id and HKDF,
`package:encrypter_plus` for AES and RSA). If one of those tests fails, the
analyser can no longer read what HealthPod writes: treat it as a compatibility
break rather than a test to adjust. To regenerate the vectors, run the same
derivations from a small Dart program depending on those packages and copy the
values across.

## Known limitations

- **Folder shares depend on key inheritance.** HealthPod gives each reading its
  own encryption key, so sharing the `blood_pressure` folder shares the
  folder's key, not the readings' keys. The analyser handles the inheritance
  case (files written with `inheritKeyFrom`) and falls back to the folder key,
  but where a file has its own key it must be shared itself. Files that cannot
  be opened are listed in `warnings` rather than silently dropped.
- **A result can cover fewer readings than were shared.** The analyser reports
  how many files it had in view, and the app says `covered 9 of your 12
  observations` beside the result when that is fewer than it granted. The
  window is small — a run has to begin between the first and last grant of a
  single press — and analysing again brings the rest in.
- **Analyses are serialised.** One Solid connection and one set of unlocked
  Pod keys are shared by every call, so a second Analyse waits for the first.
  A cohort of a few Pods analyses in seconds, so the queue is short in
  practice, and a waiting call can be cancelled without waiting it out. Making
  them concurrent means a connection and a key set per analysis, which is
  where this would go next.
- **Every contributor is read for every analysis.** The cohort figure is the
  average of their averages, so there is no avoiding it as things stand; a
  deployment with many Pods would want the per-Pod averages cached and only
  the caller's recomputed.
- **The gRPC port has to be reachable from the app**, which is a deliberate
  exposure and the one part of this arrangement that a Solid deployment does
  not otherwise need. See [Exposing the port](#exposing-the-port).
- **A browser needs a grpc-web proxy** in front of the service. See
  [Reaching it from a browser](#reaching-it-from-a-browser).
- **Timestamps are treated as UTC** when a reading carries no time zone, which
  is what HealthPod writes. This only matters at the edges of a `window_days`
  filter.
- **One application folder at a time.** `app_dir_name` is global to a run; a
  deployment analysing two applications needs two configurations and two
  services.
