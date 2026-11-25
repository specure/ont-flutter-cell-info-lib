import 'package:cell_info/CellResponse.dart';
import 'package:cell_info/SIMInfoResponse.dart';
import 'package:cell_info_example/widgets/cell_card.dart';
import 'package:cell_info_example/widgets/key_value_grid.dart';
import 'package:cell_info_example/widgets/permissions_card.dart';
import 'package:cell_info_example/widgets/sim_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  test('KeyValueGrid.flatten prefixes nested objects', () {
    expect(
      KeyValueGrid.flatten({
        'pci': 1,
        'signalLTE': {'rsrp': -95.0},
      }),
      {'pci': 1, 'signalLTE.rsrp': -95.0},
    );
  });

  testWidgets('CellCard shows technology, operator and values', (tester) async {
    final response = CellsResponse.fromJson({
      'primaryCellList': [
        {
          'type': 'LTE',
          'lte': {
            'pci': 180,
            'subscriptionId': 2,
            'connectionStatus': 'PrimaryConnection()',
            'network': {'mcc': '231', 'mnc': '01'},
            'signalLTE': {'rsrp': -95.0},
          },
        },
      ],
    });

    await tester.pumpWidget(
      _host(CellCard(cell: response.primaryCellList!.single)),
    );

    expect(find.text('LTE · 231-01 · sub 2'), findsOneWidget);
    expect(find.text('PrimaryConnection()'), findsOneWidget);
    expect(find.text('signalLTE.rsrp'), findsOneWidget);
    expect(find.text('-95.0'), findsOneWidget);
  });

  testWidgets('SimCard hides the phone number', (tester) async {
    final sim = SimInfoList(
      carrierName: 'Orange',
      subscriptionInfoNumber: '+421900000000',
      roaming: false,
    );

    await tester.pumpWidget(_host(SimCard(sim: sim)));

    expect(find.text('Orange'), findsOneWidget);
    expect(find.text('roaming'), findsOneWidget);
    expect(find.text('+421900000000'), findsNothing);
  });

  testWidgets('PermissionsCard offers to request missing permissions', (
    tester,
  ) async {
    var requested = 0;

    await tester.pumpWidget(
      _host(
        PermissionsCard(
          statuses: {
            Permission.locationWhenInUse: PermissionStatus.granted,
            Permission.phone: PermissionStatus.denied,
          },
          onRequest: () => requested++,
          onOpenSettings: () {},
        ),
      ),
    );

    expect(find.text('Phone (READ_PHONE_STATE)'), findsOneWidget);
    expect(find.text('denied'), findsOneWidget);
    await tester.tap(find.byKey(const Key('request_permissions')));
    expect(requested, 1);
    expect(find.text('Open app settings'), findsNothing);
  });

  testWidgets('PermissionsCard hides the buttons when all is granted', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PermissionsCard(
          statuses: {
            Permission.locationWhenInUse: PermissionStatus.granted,
            Permission.phone: PermissionStatus.granted,
          },
          onRequest: () {},
          onOpenSettings: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('request_permissions')), findsNothing);
  });
}
