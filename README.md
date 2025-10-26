# Health Pod &mdash; Your Health Data in your Data Vault

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

[![GitHub License](https://img.shields.io/github/license/anusii/healthpod)](https://github.com/anusii/healthpod/blob/dev/LICENSE)
[![Flutter Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/anusii/healthpod/master/pubspec.yaml&query=$.version&label=version)](https://github.com/anusii/healthpod/blob/dev/CHANGELOG.md)
[![Last Updated](https://img.shields.io/github/last-commit/anusii/healthpod?label=last%20updated)](https://github.com/anusii/healthpod/commits/dev/)
[![GitHub commit activity (dev)](https://img.shields.io/github/commit-activity/w/anusii/healthpod/dev)](https://github.com/anusii/healthpod/commits/dev/)
[![GitHub Issues](https://img.shields.io/github/issues/anusii/healthpod)](https://github.com/anusii/healthpod/issues)

A [solidui](https://github.com/anusii/solidui) based app to support
the storage and AI analysis of your health data with data encrypted
and stored on your pwn personal online data store (pod) hosted in your
Data Vault on a SOlid Server. The app was developed by the [ANU
Software Innovation Institute](https://sii.anu.edu.au) and written by
[Ashley Tang](https://github.com/atangster), [Graham
Williams](https://github.com/gjwgit), [Zheyuan
Xu](https://github.com/zheyxu), [Kevin
Wang](https://github.com/junhaow1), and [Tony
Chen](https://github.com/tonypioneer).

The latest version of the app can be run online at
[healthpod.solidcommunity.au](https://healthpod.solidcommunity.au)
with no installation required, or download and install for your
platform from the [Solid Community AU](https://solidcommunity.au):

+ **Android**
[apk](https://solidcommunity.au/installers/healthpod.apk);
+ **GNU/Linux**
[snap](https://solidcommunity.au/installers/healthpod_amd64.snap) or
[deb](https://solidcommunity.au/installers/healthpod_amd64.deb) or
[zip](https://solidcommunity.au/installers/healthpod-dev-linux.zip);
+ **macOS**
[zip](https://solidcommunity.au/installers/healthpod-dev-macos.zip);
+ **Windows**
[zip](https://solidcommunity.au/installers/healthpod-dev-windows.zip)
or
[inno](https://solidcommunity.au/installers/healthpod-dev-windows-inno.exe).

Contributions are welcome. Visit
[github](https://github.com/gjwgit/healthpod) to submit an issue or,
even better, fork the repository yourself, update the code, and submit
a Pull Request.  The app is implemented in
[Flutter](https://flutter.dev) using
[solidpod](https://pub.dev/packages/solidpod) for Flutter to manage
the Solid Pod interactions. Thank you.

## Introduction

The Health Pod collects into one private and secure location all of
your health data and medical records. Value is added to the data
through various provided tools, including privacy preserving large
language models. You collect your health data together and then you
can interact with it to review your health. You can also decide if you
want to share that data with anyone else, like you general
practitioner for them to provide their professional advice.

## Milestones

+ [X] Basic Icon-Based GUI with Solid Pod login
+ [X] Profile management with personalized profile photo upload
+ [ ] File browse my medical reports
+ [ ] Daily entry of Blood Pressure with visualisations
+ [ ] Your latest clinic data + appointments and medicines
+ [ ] Important medical information, notes and numbers
+ [ ] My vaccination history

## Design Goals

The app will work well on a desktop, web browser, a mobile phone or
tablet.

A grid of icons provides access to the functionality.

The grid items include:

+ Obs (A feature to record daily or regular observations like
  blood pressure, physical activity, etc)

+ Activity (A record of activities recording date, start, end, what)

+ Diary (A record of visits to doctors, dentists, pharmacy,
  vaccinations, etc. Each diary entry records: date, what, details,
  provider, professional, total, covered, cost)

+ Docs (A file browser type of thing where the user can arrange their
  PDFs into appropriate folders as they like.)

## Use Cases

+ I am visiting the doctor and I need to check when I last had a
  vaccination

+ A LLM model runs over the whole contents of the Pod to then allow me
  to interact with the data collection.

Time-stamp: *<Thursday 2025-10-16 08:46:39 +1100 Graham Williams>*

<!-- markdownlint-disable MD053 -->
[comment]: # (Local Variables:)
[comment]: # (time-stamp-line-limit: -8)
[comment]: # (End:)
<!-- markdownlint-enable MD053 -->
