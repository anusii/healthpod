/// Tests for deciding which writes inherit their observation folder's key.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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

import 'package:flutter_test/flutter_test.dart';

import 'package:healthpod/features/bp/analyser/share_service.dart';
import 'package:healthpod/utils/observation_folder_key.dart';

void main() {
  group('observationKeyFolder', () {
    test('a reading in the blood pressure folder uses the folder key', () {
      expect(
        observationKeyFolder('blood_pressure/blood_pressure_x.json.enc.ttl'),
        'blood_pressure',
      );
    });

    test('a leading slash makes no difference', () {
      expect(
        observationKeyFolder('/blood_pressure/blood_pressure_x.json.enc.ttl'),
        'blood_pressure',
      );
    });

    test('other feature folders keep a key per file', () {
      expect(observationKeyFolder('vaccination/v.json.enc.ttl'), isNull);
      expect(observationKeyFolder('diary/d.json.enc.ttl'), isNull);
    });

    test('a file at the top of the data folder keeps its own key', () {
      expect(observationKeyFolder('blood_pressure.json.enc.ttl'), isNull);
    });

    test('a folder whose name only starts the same does not match', () {
      expect(observationKeyFolder('blood_pressure_old/x.enc.ttl'), isNull);
    });

    test('the Analyser shares a folder that inherits its key', () {
      expect(
        observationFolders,
        contains(BPAnalyserShareService.feature),
      );
    });
  });

  group('classifyObservationContent', () {
    const prefix =
        '@prefix solidTerms: <https://solidcommunity.au/predicates/terms#> .\n';
    const url =
        '<https://pod.example/u/healthpod/data/blood_pressure/a.json.enc.ttl>';

    String encrypted({String? inheritFrom}) => '$prefix$url\n'
        '    solidTerms:iv "aXY=";\n'
        '${inheritFrom == null ? '' : '    solidTerms:inheritKeyFrom "$inheritFrom";\n'}'
        '    solidTerms:encData "ZGF0YQ==".\n';

    test('a reading on its folder key is recognised', () {
      final result = classifyObservationContent(
        encrypted(inheritFrom: 'healthpod/data/blood_pressure/'),
        'blood_pressure',
      );
      expect(result.storage, ObservationStorage.folderKey);
    });

    test('the folder path is compared without its slashes mattering', () {
      final result = classifyObservationContent(
        encrypted(inheritFrom: '/healthpod/data/blood_pressure'),
        'blood_pressure',
      );
      expect(result.storage, ObservationStorage.folderKey);
    });

    test('a full predicate URI written out by the server is understood', () {
      final content = '$url\n'
          '  <https://solidcommunity.au/predicates/terms#inheritKeyFrom> '
          '"healthpod/data/blood_pressure/";\n'
          '  <https://solidcommunity.au/predicates/terms#encData> "ZGF0YQ==".';
      expect(
        classifyObservationContent(content, 'blood_pressure').storage,
        ObservationStorage.folderKey,
      );
    });

    test('plaintext JSON is recognised', () {
      expect(
        classifyObservationContent('{"timestamp": "x"}', 'blood_pressure')
            .storage,
        ObservationStorage.plaintext,
      );
    });

    test('another folder key is reported with the folder it names', () {
      final result = classifyObservationContent(
        encrypted(inheritFrom: 'healthpod/data/old_bp/'),
        'blood_pressure',
      );
      expect(result.storage, ObservationStorage.otherFolderKey);
      expect(result.keyFolder, 'healthpod/data/old_bp/');
    });

    test('encrypted content naming no key has lost it', () {
      expect(
        classifyObservationContent(encrypted(), 'blood_pressure').storage,
        ObservationStorage.keyLost,
      );
    });
  });
}
