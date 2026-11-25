import 'dart:convert';

import 'package:cell_info/CellResponse.dart';
import 'package:cell_info/SIMInfoResponse.dart';
import 'package:cell_info/cell_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runs against the real plugin and the real NetMonster Core on a device or emulator.
///
/// The test adapts to the permission state of the app, so both halves of the contract can be
/// checked (see tool/run_device_tests.sh, which runs it once with and once without permissions):
///  - permissions missing -> both calls return null
///  - permissions granted -> both calls return JSON that the Dart models understand
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Set by tool/device_test.sh to `granted` or `denied`; empty when the test is run by hand.
  const expectedPermissions = String.fromEnvironment('EXPECT_PERMISSIONS');

  Future<bool> permissionsGranted() async {
    final granted =
        await Permission.locationWhenInUse.isGranted &&
        await Permission.phone.isGranted;
    if (expectedPermissions.isNotEmpty) {
      expect(
        granted ? 'granted' : 'denied',
        expectedPermissions,
        reason:
            'the app is not in the permission state this run is meant to test',
      );
    }
    return granted;
  }

  testWidgets('getCellInfo honours permissions and the JSON contract', (
    tester,
  ) async {
    final granted = await permissionsGranted();
    final raw = await CellInfo.getCellInfo;

    if (!granted) {
      expect(
        raw,
        isNull,
        reason: 'no data may be returned without permissions',
      );
      return;
    }

    expect(raw, isNotNull, reason: 'permissions are granted, data expected');
    final Map<String, dynamic> body = json.decode(raw!);
    expect(
      body.keys,
      unorderedEquals([
        'primaryCellList',
        'neighboringCellList',
        'cellDataList',
      ]),
    );

    final response = CellsResponse.fromJson(body);
    final rawCells = [
      ...body['primaryCellList'] as List,
      ...body['neighboringCellList'] as List,
    ].cast<Map<String, dynamic>>();
    final cells = [
      ...response.primaryCellList!,
      ...response.neighboringCellList!,
    ];
    // ignore: avoid_print
    print(
      'cell_info: ${response.primaryCellList!.length} primary, '
      '${response.neighboringCellList!.length} neighbouring cells: '
      '${cells.map((c) => c.type).join(', ')}',
    );

    expect((body['cellDataList'] as List).length, cells.length);

    for (var i = 0; i < cells.length; i++) {
      final raw = rawCells[i];
      expect(_cellTypeKeys, containsAll(raw.keys), reason: 'cell $i: $raw');
      expect(_technologies, contains(raw['type']));

      // Exactly one technology specific object, and the Dart model reproduces all its keys.
      final technologyKeys = raw.keys.where(_technologyKeys.contains).toList();
      expect(technologyKeys, hasLength(1), reason: 'cell $i: $raw');
      final nativeDetails = raw[technologyKeys.single] as Map<String, dynamic>;
      final dartDetails =
          cells[i].toJson()[technologyKeys.single] as Map<String, dynamic>;
      _expectKeysKnown(nativeDetails, dartDetails, 'cell $i');
      expect(nativeDetails['connectionStatus'], isA<String>());
      expect(nativeDetails['subscriptionId'], isA<int>());
    }

    for (final Map<String, dynamic> primary in body['primaryCellList']) {
      expect(primary['networkType'], isA<String>());
    }

    for (final Map<String, dynamic> cellData in body['cellDataList']) {
      expect(cellData['timestamp'], greaterThan(0));
      expect(_technologies, contains(cellData['type']));
      // Device details are filled from android.os.Build.
      expect(cellData['mODEL'], isA<String>());
      expect(cellData['mANUFACTURER'], isA<String>());
      expect(cellData['rELEASE'], isA<String>());
    }
  });

  testWidgets('getSIMInfo honours permissions and the JSON contract', (
    tester,
  ) async {
    final granted = await permissionsGranted();
    final raw = await CellInfo.getSIMInfo;

    if (!granted) {
      expect(
        raw,
        isNull,
        reason: 'no data may be returned without permissions',
      );
      return;
    }

    expect(raw, isNotNull);
    final Map<String, dynamic> body = json.decode(raw!);
    expect(body['error'], isNull, reason: 'native failed to read SIM info');
    expect(body['simInfoList'], isA<List>());

    final response = SIMInfoResponse.fromJson(body);
    // ignore: avoid_print
    print('sim_info: ${response.simInfoList!.length} active SIM(s)');
    for (final Map<String, dynamic> sim in body['simInfoList']) {
      expect(_simKeys, containsAll(sim.keys));
      expect(sim['subscriptionId'], isA<int>());
      expect(sim['roaming'], isA<bool>());
      expect(sim['isDefaultDataSubscription'], isA<bool>());
    }
  });
}

const _technologies = {'GSM', 'CDMA', 'WCDMA', 'TDSCDMA', 'LTE', 'NR'};
const _technologyKeys = {'gsm', 'cdma', 'wcdma', 'tdscdma', 'lte', 'nr'};

const _cellTypeKeys = {
  'type',
  'networkType',
  ..._technologyKeys,
  'nrAvailable',
  'enDcAvailable',
  'nrConnected',
  'nrConnectionStatus',
  'nrRejectedReason',
};

const _simKeys = {
  'carrierName',
  'displayName',
  'mcc',
  'mnc',
  'subscriptionInfoNumber',
  'subscriptionId',
  'countryIso',
  'networkCountryIso',
  'roaming',
  'isDefaultDataSubscription',
};

/// Every key native sent must come back out of the Dart model, recursively.
void _expectKeysKnown(
  Map<String, dynamic> native,
  Map<String, dynamic> dart,
  String path,
) {
  native.forEach((key, value) {
    expect(
      dart.containsKey(key),
      isTrue,
      reason: '$path.$key is sent by native but unknown to the Dart model',
    );
    if (value is Map<String, dynamic>) {
      _expectKeysKnown(value, dart[key] as Map<String, dynamic>, '$path.$key');
    } else {
      expect(dart[key], value, reason: '$path.$key');
    }
  });
}
