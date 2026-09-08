/// A gRPC channel over HTTP/2, for every platform with a socket.
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

import 'package:grpc/grpc.dart' as grpc;
import 'package:grpc/service_api.dart' show ClientChannel;

/// A channel to the analyser at [host] and [port].
///
/// [secure] picks TLS, which the analyser serves when it has been given a
/// certificate. The return type is the interface both channels satisfy rather
/// than this library's own class, so the caller compiles unchanged against
/// either — see `channel.dart`.

ClientChannel createAnalyserChannel({
  required String host,
  required int port,
  required bool secure,
}) =>
    grpc.ClientChannel(
      host,
      port: port,
      options: grpc.ChannelOptions(
        credentials: secure
            ? const grpc.ChannelCredentials.secure()
            : const grpc.ChannelCredentials.insecure(),

        // A deployment that is not running answers a connection attempt at
        // once, so the app finds out within a second rather than after the
        // twenty that gRPC would otherwise spend backing off and retrying.

        connectionTimeout: const Duration(seconds: 5),
      ),
    );
