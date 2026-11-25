import 'dart:async';
import 'dart:convert';

import 'package:cell_info/CellResponse.dart';
import 'package:cell_info/SIMInfoResponse.dart';
import 'package:cell_info/cell_info.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

import 'widgets/cell_card.dart';
import 'widgets/permissions_card.dart';
import 'widgets/sim_card.dart';

void main() {
  runApp(const CellInfoExampleApp());
}

class CellInfoExampleApp extends StatelessWidget {
  const CellInfoExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'cell_info example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

/// The two runtime permissions the plugin needs before it returns any data.
const requiredPermissions = <Permission>[
  Permission.locationWhenInUse, // ACCESS_FINE_LOCATION
  Permission.phone, // READ_PHONE_STATE
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Map<Permission, PermissionStatus> _permissions = {};
  CellsResponse? _cells;
  SIMInfoResponse? _sims;
  String? _rawCells;
  String? _rawSims;

  /// What the last plugin call did, in words. Shown at the top so permission problems are visible.
  String _status = 'Not loaded yet';
  bool _autoRefresh = true;
  bool _loading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_autoRefresh) _refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the system settings screen: permissions may have changed.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _requestPermissions() async {
    await requiredPermissions.request();
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    _loading = true;

    final permissions = <Permission, PermissionStatus>{
      for (final permission in requiredPermissions)
        permission: await permission.status,
    };

    CellsResponse? cells;
    SIMInfoResponse? sims;
    String? rawCells;
    String? rawSims;
    String status;
    try {
      rawCells = await CellInfo.getCellInfo;
      rawSims = await CellInfo.getSIMInfo;

      if (rawCells == null) {
        status =
            'getCellInfo returned null: the plugin does this when the '
            'location or phone permission is not granted.';
      } else {
        cells = CellsResponse.fromJson(json.decode(rawCells));
        status =
            '${cells.primaryCellList?.length ?? 0} primary, '
            '${cells.neighboringCellList?.length ?? 0} neighbouring cells';
      }

      if (rawSims != null) {
        final Map<String, dynamic> simsJson = json.decode(rawSims);
        sims = SIMInfoResponse.fromJson(simsJson);
        if (simsJson['error'] != null) {
          status += '\nSIM info error: ${simsJson['error']}';
        }
      }
    } on PlatformException catch (e) {
      status = 'PlatformException: ${e.code} ${e.message}';
    } catch (e) {
      status = 'Failed to parse the plugin response: $e';
    }

    _loading = false;
    if (!mounted) return;
    setState(() {
      _permissions = permissions;
      _cells = cells;
      _sims = sims;
      _rawCells = rawCells;
      _rawSims = rawSims;
      _status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = _cells?.primaryCellList ?? const [];
    final neighbours = _cells?.neighboringCellList ?? const [];
    final sims = _sims?.simInfoList ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('cell_info example'),
        actions: [
          IconButton(
            key: const Key('refresh'),
            tooltip: 'Refresh now',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            PermissionsCard(
              statuses: _permissions,
              onRequest: _requestPermissions,
              onOpenSettings: openAppSettings,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    Expanded(child: Text(_status, key: const Key('status'))),
                    const Text('Auto'),
                    Switch(
                      value: _autoRefresh,
                      onChanged: (value) =>
                          setState(() => _autoRefresh = value),
                    ),
                  ],
                ),
              ),
            ),
            _SectionTitle('SIM cards (${sims.length})'),
            for (final sim in sims) SimCard(sim: sim),
            _SectionTitle('Primary cells (${primary.length})'),
            for (final cell in primary) CellCard(cell: cell),
            _SectionTitle('Neighbouring cells (${neighbours.length})'),
            for (final cell in neighbours) CellCard(cell: cell),
            ExpansionTile(
              title: const Text('Raw JSON from the plugin'),
              childrenPadding: const EdgeInsets.all(12),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('getCellInfo', style: theme.textTheme.titleSmall),
                SelectableText(_pretty(_rawCells)),
                const SizedBox(height: 12),
                Text('getSIMInfo', style: theme.textTheme.titleSmall),
                SelectableText(_pretty(_rawSims)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _pretty(String? raw) {
    if (raw == null) return 'null';
    try {
      return const JsonEncoder.withIndent('  ').convert(json.decode(raw));
    } catch (_) {
      return raw;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
