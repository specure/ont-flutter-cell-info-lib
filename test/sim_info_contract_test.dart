import 'dart:convert';

import 'package:cell_info/SIMInfoResponse.dart';
import 'package:flutter_test/flutter_test.dart';

/// SIM info comes straight from the Android SDK (not from NetMonster Core), so its JSON is
/// pinned here by hand. Keys match the fields of the Kotlin `SIMInfo` class.
void main() {
  const nativeJson = '''
  {
    "simInfoList": [
      {
        "carrierName": "Orange",
        "displayName": "Work",
        "mcc": 231,
        "mnc": 1,
        "subscriptionInfoNumber": "",
        "subscriptionId": 1,
        "countryIso": "sk",
        "networkCountryIso": "sk",
        "roaming": false,
        "isDefaultDataSubscription": true
      },
      {
        "carrierName": "UNKNOWN",
        "displayName": "UNKNOWN",
        "mcc": 230,
        "mnc": 3,
        "subscriptionId": 2,
        "countryIso": "cz",
        "networkCountryIso": "sk",
        "roaming": true,
        "isDefaultDataSubscription": false
      }
    ]
  }''';

  test('parses every field native sends', () {
    final response = SIMInfoResponse.fromJson(json.decode(nativeJson));

    expect(response.simInfoList, hasLength(2));
    final first = response.simInfoList![0];
    expect(first.carrierName, 'Orange');
    expect(first.displayName, 'Work');
    expect(first.mcc, 231);
    expect(first.mnc, 1);
    expect(first.subscriptionInfoNumber, '');
    expect(first.subscriptionId, 1);
    expect(first.countryIso, 'sk');
    expect(first.networkCountryIso, 'sk');
    expect(first.roaming, false);
    expect(first.isDefaultDataSubscription, true);

    final second = response.simInfoList![1];
    expect(second.subscriptionInfoNumber, isNull);
    expect(second.roaming, true);
    expect(second.isDefaultDataSubscription, false);
  });

  test('toJson exposes exactly the native keys', () {
    final response = SIMInfoResponse.fromJson(json.decode(nativeJson));

    expect(
      response.toJson()['simInfoList'][0].keys,
      unorderedEquals([
        'carrierName',
        'displayName',
        'mcc',
        'mnc',
        'subscriptionInfoNumber',
        'subscriptionId',
        'isDefaultDataSubscription',
        'countryIso',
        'networkCountryIso',
        'roaming',
      ]),
    );
  });

  test('error replies carry an empty list and an `error` string', () {
    final Map<String, dynamic> body = json.decode(
      '{"simInfoList":[],"error":"java.lang.SecurityException: ..."}',
    );

    expect(SIMInfoResponse.fromJson(body).simInfoList, isEmpty);
    expect(body['error'], isA<String>());
  });
}
