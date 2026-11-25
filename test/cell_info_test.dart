import 'package:cell_info/cell_info.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the method channel contract between Dart and the Android side: channel names,
/// method names, no arguments, and a nullable JSON string as the reply.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cellInfoChannel = MethodChannel('cell_info');
  const simInfoChannel = MethodChannel('sim_info');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final calls = <String, List<MethodCall>>{};

  void mock(MethodChannel channel, Object? Function(MethodCall call) reply) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.putIfAbsent(channel.name, () => []).add(call);
      return reply(call);
    });
  }

  setUp(calls.clear);

  tearDown(() {
    messenger.setMockMethodCallHandler(cellInfoChannel, null);
    messenger.setMockMethodCallHandler(simInfoChannel, null);
  });

  test('getCellInfo calls `cell_info` on the `cell_info` channel', () async {
    mock(cellInfoChannel, (_) => '{"primaryCellList":[]}');

    expect(await CellInfo.getCellInfo, '{"primaryCellList":[]}');

    expect(calls.keys, ['cell_info']);
    expect(calls['cell_info']!.single.method, 'cell_info');
    expect(calls['cell_info']!.single.arguments, isNull);
  });

  test('getSIMInfo calls `sim_info` on the `sim_info` channel', () async {
    mock(simInfoChannel, (_) => '{"simInfoList":[]}');

    expect(await CellInfo.getSIMInfo, '{"simInfoList":[]}');

    expect(calls.keys, ['sim_info']);
    expect(calls['sim_info']!.single.method, 'sim_info');
    expect(calls['sim_info']!.single.arguments, isNull);
  });

  test('null replies (missing permissions) are passed through', () async {
    mock(cellInfoChannel, (_) => null);
    mock(simInfoChannel, (_) => null);

    expect(await CellInfo.getCellInfo, isNull);
    expect(await CellInfo.getSIMInfo, isNull);
  });

  test('native errors surface as PlatformException', () async {
    mock(
      cellInfoChannel,
      (_) => throw PlatformException(code: 'CELL_INFO_ERROR', message: 'boom'),
    );

    expect(
      () => CellInfo.getCellInfo,
      throwsA(
        isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'CELL_INFO_ERROR',
        ),
      ),
    );
  });
}
