/// Widget for displaying transport information and options.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
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
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Zheyuan Xu, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:healthpod/features/home/service/components/widgets/audio_player_widget.dart';

/// Widget that displays transport information including clinic bus
/// availability and phone assistance.

class TransportInfoWidget extends StatelessWidget {
  const TransportInfoWidget({
    super.key,
    required this.useClinicBus,
    required this.needsTransport,
    required this.transportPhone,
    required this.transportNote,
  });

  final bool useClinicBus;
  final bool needsTransport;
  final String transportPhone;
  final String transportNote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (useClinicBus)
          Row(
            children: [
              const Icon(Icons.directions_bus, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Transport:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.check, color: Colors.green),
            ],
          ),
        if (needsTransport) ...[
          const SizedBox(height: 16),
          const Text(
            'Need help with transport?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Call $transportPhone ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: transportNote,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const TextSpan(
                        text: ' to change or request transport.',
                      ),
                    ],
                  ),
                ),
              ),
              const AudioPlayerWidget(),
            ],
          ),
        ],
      ],
    );
  }
}
