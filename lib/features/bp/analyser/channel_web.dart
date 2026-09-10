/// A grpc-web channel, for the browser build.
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

import 'package:grpc/grpc_web.dart';
import 'package:grpc/service_api.dart' show ClientChannel;

/// A channel to the analyser at [host] and [port], over grpc-web.
///
/// A browser cannot open the HTTP/2 socket that gRPC proper needs, so this
/// speaks grpc-web instead: the same messages over ordinary HTTP requests. The
/// analyser does not serve that format, so a deployment used from the browser
/// needs a translating proxy in front of it — Envoy's `grpc_web` filter is the
/// usual one, and `analyser/bp_analyser/README.md` says how under "Reaching it
/// from a browser".
///
/// [host] and [port] are therefore the proxy's, not the analyser's, and
/// [secure] should be true for anything but a local trial: a browser on an
/// HTTPS page will not call an insecure endpoint at all.

ClientChannel createAnalyserChannel({
  required String host,
  required int port,
  required bool secure,
}) =>
    GrpcWebClientChannel.xhr(
      Uri.parse('${secure ? 'https' : 'http'}://$host:$port'),
    );
