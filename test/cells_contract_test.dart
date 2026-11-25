import 'dart:convert';
import 'dart:io';

import 'package:cell_info/CellResponse.dart';
import 'package:cell_info/models/common/cell_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks the Dart models against the JSON the Android side really produces.
///
/// The fixtures in test/fixtures are written by the Kotlin `CellsResponseContractTest`, which
/// runs the plugin's mapping code against the pinned NetMonster Core. If these tests and the
/// Kotlin test are green after a NetMonster Core update, Flutter code sees the same data.
void main() {
  Map<String, dynamic> fixture(String name) =>
      json.decode(File('test/fixtures/$name.json').readAsStringSync());

  CellsResponse parse(String name) => CellsResponse.fromJson(fixture(name));

  group('every fixture', () {
    final files =
        Directory('test/fixtures')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    test('fixtures exist', () {
      expect(files.length, greaterThanOrEqualTo(6));
    });

    for (final file in files) {
      final name = file.uri.pathSegments.last;

      test('$name: Dart models understand everything native sends', () {
        final Map<String, dynamic> native = json.decode(
          file.readAsStringSync(),
        );
        expect(
          native.keys,
          unorderedEquals([
            'primaryCellList',
            'neighboringCellList',
            'cellDataList',
          ]),
        );

        final response = CellsResponse.fromJson(native);
        for (final list in ['primaryCellList', 'neighboringCellList']) {
          final nativeCells = (native[list] as List)
              .cast<Map<String, dynamic>>();
          final dartCells = list == 'primaryCellList'
              ? response.primaryCellList!
              : response.neighboringCellList!;
          expect(dartCells, hasLength(nativeCells.length));

          for (var i = 0; i < nativeCells.length; i++) {
            final expected = Map<String, dynamic>.of(nativeCells[i])
              ..removeWhere((key, _) => _notModelledInDart.contains(key));
            expectContains(
              actual: dartCells[i].toJson(),
              expected: expected,
              path: '$list[$i]',
            );
          }
        }
      });

      test('$name: cellDataList only uses known keys', () {
        final Map<String, dynamic> native = json.decode(
          file.readAsStringSync(),
        );
        for (final Map<String, dynamic> cellData in native['cellDataList']) {
          expect(_cellDataKeys, containsAll(cellData.keys));
          expect(cellData['timestamp'], isA<int>());
          expect(cellData['type'], isA<String>());
        }
      });
    }
  });

  group('values', () {
    test('LTE primary cell with a neighbour', () {
      final response = parse('cells_lte');
      final primary = response.primaryCellList!.single;

      expect(primary.type, 'LTE');
      final lte = primary.lte!;
      expect(lte.type, 'LTE');
      expect(lte.eci, 26373121);
      expect(lte.enb, 103020);
      expect(lte.cid, 1);
      expect(lte.tac, 4021);
      expect(lte.pci, 180);
      expect(lte.ecgi, '231010026373121');
      expect(lte.bandwidth, 20000);
      expect(lte.subscriptionId, 1);
      expect(lte.connectionStatus, 'PrimaryConnection()');
      expect(lte.network!.mcc, '231');
      expect(lte.network!.mnc, '01');
      expect(lte.network!.iso, 'SK');
      expect(lte.bandLTE!.downlinkEarfcn, 1300);
      expect(lte.bandLTE!.channelNumber, 1300);
      expect(lte.bandLTE!.number, 3);
      expect(lte.bandLTE!.name, '1800');
      expect(lte.signalLTE!.rssi, -65);
      expect(lte.signalLTE!.rsrp, -95.0);
      expect(lte.signalLTE!.rsrq, -9.5);
      expect(lte.signalLTE!.snr, 12.4);
      expect(lte.signalLTE!.cqi, 11);
      expect(lte.signalLTE!.timingAdvance, 3);
      expect(lte.signalLTE!.rssiAsu, 24);
      expect(lte.signalLTE!.rsrpAsu, 45);
      expect(lte.signalLTE!.dbm, -65);

      final neighbour = response.neighboringCellList!.single.lte!;
      expect(neighbour.connectionStatus, 'NoneConnection()');
      expect(neighbour.pci, 301);
      expect(neighbour.eci, isNull);
      // Absent values stay null instead of turning into 0.
      expect(neighbour.signalLTE!.rssi, isNull);
      expect(neighbour.signalLTE!.rsrp, -105.0);
      expect(neighbour.network!.mcc, isNull);
    });

    test('NR non-standalone: LTE anchor is primary, NR is a neighbour', () {
      final response = parse('cells_nr_nsa');

      expect(response.primaryCellList!.single.type, 'LTE');
      final nr = response.neighboringCellList!.single;
      expect(nr.type, 'NR');
      expect(nr.nr!.connectionStatus, 'SecondaryConnection(isGuess=false)');
      expect(nr.nr!.nci, isNull);
      expect(nr.nr!.pci, 512);
      expect(nr.nr!.bandNR!.downlinkArfcn, 630048);
      expect(nr.nr!.bandNR!.downlinkFrequency, 3450720);
      expect(nr.nr!.bandNR!.number, 78);
      expect(nr.nr!.signalNR!.ssRsrp, -89);
      expect(nr.nr!.signalNR!.ssRsrpAsu, 51);
      expect(nr.nr!.signalNR!.csiRsrp, -91);
      expect(nr.nr!.signalNR!.dbm, -89);

      // Sent by native on the primary cell; not modelled by CellType, read from raw JSON.
      final rawPrimary =
          (fixture('cells_nr_nsa')['primaryCellList'] as List).single;
      expect(rawPrimary['networkType'], '2147483644');
      expect(rawPrimary['nrAvailable'], true);
      expect(rawPrimary['enDcAvailable'], true);
      expect(rawPrimary['nrConnected'], true);
      expect(rawPrimary['nrConnectionStatus'], 'connected');
    });

    test('NR standalone', () {
      final nr = parse('cells_nr_sa').primaryCellList!.single;

      expect(nr.type, 'NR');
      expect(nr.nr!.nci, 8612167681);
      expect(nr.nr!.tac, 1401);
      expect(nr.nr!.network!.mcc, '231');

      final raw = (fixture('cells_nr_sa')['primaryCellList'] as List).single;
      expect(raw['networkType'], '20');
      expect(raw.containsKey('nrConnected'), isFalse);
    });

    test('dual SIM: cells keep their subscription id', () {
      final response = parse('cells_dual_sim');

      expect(response.primaryCellList!.map((c) => c.type), ['LTE', 'WCDMA']);
      expect(response.primaryCellList![0].lte!.subscriptionId, 1);
      expect(response.primaryCellList![1].wcdma!.subscriptionId, 2);
      expect(response.neighboringCellList!.single.gsm!.subscriptionId, 2);

      final raw = fixture('cells_dual_sim')['primaryCellList'] as List;
      expect(raw[0]['nrConnectionStatus'], 'rejected');
      expect(raw[0]['nrRejectedReason'], 'RESTRICTED');
      expect(raw[0]['nrConnected'], false);
      // NSA details are only attached to LTE / NR cells.
      expect(raw[1].containsKey('nrConnectionStatus'), isFalse);
    });

    test('GSM, WCDMA, CDMA and TD-SCDMA', () {
      final cells = parse('cells_legacy').primaryCellList!;

      final gsm = cells[0].gsm!;
      expect(cells[0].type, 'GSM');
      expect(gsm.cid, 20441);
      expect(gsm.lac, 5021);
      expect(gsm.bsic, 43);
      expect(gsm.bandGSM!.arfcn, 77);
      expect(gsm.signalGSM!.rssi, -79);
      expect(gsm.signalGSM!.bitErrorRate, 1);
      expect(gsm.signalGSM!.timingAdvance, 2);

      final wcdma = cells[1].wcdma!;
      expect(cells[1].type, 'WCDMA');
      expect(wcdma.ci, 13180203);
      expect(wcdma.cid, 7467);
      expect(wcdma.rnc, 201);
      expect(wcdma.psc, 318);
      expect(wcdma.cgi, '231010502107467');
      expect(wcdma.bandWCDMA!.channelNumber, 10588);
      expect(wcdma.signalWCDMA!.rscp, -84);
      expect(wcdma.signalWCDMA!.ecno, -8);
      expect(wcdma.signalWCDMA!.ecio, -6);

      // Legacy quirk: CDMA cells arrive with the outer type "WCDMA".
      final cdma = cells[2].cdma!;
      expect(cells[2].type, 'WCDMA');
      expect(cdma.type, 'CDMA');
      expect(cdma.sid, 4139);
      expect(cdma.nid, 41);
      expect(cdma.bid, 4562);
      expect(cdma.lat, 50.0755);
      expect(cdma.lon, 14.4378);
      expect(cdma.signalCDMA!.cdmaRssi, -88);
      expect(cdma.signalCDMA!.cdmaEcio, -7.5);
      expect(cdma.signalCDMA!.evdoEcio, -6.0);
      expect(cdma.signalCDMA!.evdoSnr, 6);

      final tdscdma = cells[3].tdscdma!;
      expect(cells[3].type, 'TDSCDMA');
      expect(tdscdma.cpid, 66);
      expect(tdscdma.bandTDSCDMA!.downlinkUarfcn, 10080);
      expect(tdscdma.signalTDSCDMA!.rscp, -86);
    });

    test('empty response', () {
      final response = parse('cells_empty');

      expect(response.primaryCellList, isEmpty);
      expect(response.neighboringCellList, isEmpty);
    });

    test('CellType survives a toJson / fromJson round trip', () {
      for (final name in ['cells_lte', 'cells_nr_sa', 'cells_legacy']) {
        for (final cell in parse(name).primaryCellList!) {
          final copy = CellType.fromJson(
            json.decode(json.encode(cell.toJson())),
          );
          expect(copy.toJson(), cell.toJson());
        }
      }
    });
  });
}

/// Keys the Android side sends on each cell that `CellType` has never exposed. Flutter code
/// that needs them reads the raw JSON. Listed here so that a *new* unknown key fails the test.
const _notModelledInDart = {
  'networkType',
  'nrAvailable',
  'enDcAvailable',
  'nrConnected',
  'nrConnectionStatus',
  'nrRejectedReason',
};

/// All keys a `cellDataList` entry may carry (flat view of every cell, plus device details).
const _cellDataKeys = {
  'timestamp', 'type', 'subscriptionId', 'connectionStatus', 'mcc', 'mnc', 'iso', //
  'sid', 'nid', 'bid', 'lat', 'lon', 'bandChannelNumber', 'bandNumber', 'bandName', //
  'cdmaRssi', 'evdoRssi', 'evdoSnr', 'cdmaEcio', 'evdoEcio', 'cid', 'lac', 'bsic', //
  'ncc', 'bcc', 'cgi', 'dbm', 'rssi', 'bitErrorRate', 'timingAdvance', 'bandwidth', //
  'eci', 'tac', 'pci', 'enb', 'ecgi', 'downlinkEarfcn', 'rsrp', 'rsrq', 'snr', 'cqi', //
  'rssiAsu', 'rsrpAsu', 'nci', 'bandDownlinkArfcn', 'bandDownlinkFrequency', //
  'csiRsrp', 'csiRsrq', 'csiSinr', 'ssRsrp', 'ssRsrq', 'ssSinr', 'csiRsrpAsu', //
  'ssRsrpAsu', 'ci', 'cpid', 'rnc', 'downlinkUarfcn', 'rscp', 'rscpAsu', 'psc', //
  'ecno', 'ecio', 'arfcn', //
  'oSVERSION', 'rELEASE', 'dEVICE', 'mODEL', 'pRODUCT', 'bRAND', 'dISPLAY', //
  'cPU_ABI', 'cPU_ABI2', 'uNKNOWN', 'hARDWARE', 'iD', 'mANUFACTURER', 'sERIAL', //
  'uSER', 'hOST',
};

/// Asserts that every key/value in [expected] (what native sent) is reproduced by [actual]
/// (what the Dart model re-serializes), recursively. Fails with the JSON path of the mismatch,
/// e.g. when native starts sending a key the Dart model does not know.
void expectContains({
  required Object? actual,
  required Object? expected,
  required String path,
}) {
  if (expected is Map<String, dynamic>) {
    expect(actual, isA<Map<String, dynamic>>(), reason: '$path is missing');
    final actualMap = actual as Map<String, dynamic>;
    expected.forEach((key, value) {
      expect(
        actualMap.containsKey(key),
        isTrue,
        reason: '$path.$key is sent by native but unknown to the Dart model',
      );
      expectContains(
        actual: actualMap[key],
        expected: value,
        path: '$path.$key',
      );
    });
  } else {
    expect(actual, expected, reason: '$path differs');
  }
}
