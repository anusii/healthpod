/// Opening a channel to the analyser, on whichever platform this is.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Tony Chen

library;

import 'package:grpc/service_api.dart' show ClientChannel;

import 'channel_native.dart' if (dart.library.js_interop) 'channel_web.dart'
    as platform;

// gRPC over HTTP/2 needs a socket, and a browser does not have one. So there
// are two channels, chosen at compile time, and this is the seam between
// them: everything above it — `analyser_client.dart` and the generated stubs —
// is written once and does not know which it has.
//
// `channel_native.dart` is the real thing, and is what the desktop and mobile
// builds use. `channel_web.dart` is grpc-web, which speaks a different wire
// format and therefore needs something in front of the analyser to translate
// it; see "Reaching it from a browser" in analyser/bp_analyser/README.md. The
// web build compiles and calls either way, which is the point of having it:
// nothing here breaks a build that cannot use it.
//
// Importing `package:grpc/grpc.dart` unconditionally is what makes this
// necessary. That library reaches for dart:io, so a single import of it would
// stop the web build compiling at all.
//
// The seam is a conditional import and a function that passes the call
// straight on, rather than the conditional export it reads like it should be.
// The difference is what static analysis can see: a tool resolves the
// directive the way this platform would, so an export names the native
// library and the web one is left looking like a file nobody wants — dead
// code, on a reading that would be true if the web build did not exist. An
// import records every branch, and a call through the prefix counts as a call
// into all of them, so both channels are accounted for.

/// A channel to the analyser at [host] and [port], on whichever platform this
/// is.
///
/// [secure] picks TLS on the native channel, and on the web is not optional in
/// practice: a browser on an HTTPS page will not call an insecure endpoint at
/// all. On the web [host] and [port] are the translating proxy's rather than
/// the analyser's.

ClientChannel createAnalyserChannel({
  required String host,
  required int port,
  required bool secure,
}) =>
    platform.createAnalyserChannel(host: host, port: port, secure: secure);
