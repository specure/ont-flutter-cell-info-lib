import 'package:cell_info/models/common/cell_type.dart';
import 'package:material_ui/material_ui.dart';

import 'key_value_grid.dart';

class CellCard extends StatelessWidget {
  const CellCard({super.key, required this.cell});

  final CellType cell;

  /// The technology specific part of the cell, whichever one the plugin filled in.
  Map<String, dynamic> get _details =>
      cell.lte?.toJson() ??
      cell.nr?.toJson() ??
      cell.wcdma?.toJson() ??
      cell.gsm?.toJson() ??
      cell.cdma?.toJson() ??
      cell.tdscdma?.toJson() ??
      const {};

  @override
  Widget build(BuildContext context) {
    final details = Map<String, dynamic>.of(_details);
    final network = details['network'] as Map<String, dynamic>?;
    final subscriptionId = details.remove('subscriptionId');
    final connection = details.remove('connectionStatus');
    details.remove('type');

    final headline = [
      cell.type ?? 'unknown',
      if (network?['mcc'] != null) '${network!['mcc']}-${network['mnc']}',
      if (subscriptionId != null) 'sub $subscriptionId',
    ].join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headline, style: Theme.of(context).textTheme.titleSmall),
            if (connection != null)
              Text('$connection', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            KeyValueGrid(values: details),
          ],
        ),
      ),
    );
  }
}
