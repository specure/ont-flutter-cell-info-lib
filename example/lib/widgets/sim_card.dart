import 'package:cell_info/SIMInfoResponse.dart';
import 'package:material_ui/material_ui.dart';

import 'key_value_grid.dart';

class SimCard extends StatelessWidget {
  const SimCard({super.key, required this.sim});

  final SimInfoList sim;

  @override
  Widget build(BuildContext context) {
    final details = sim.toJson()
      ..remove('carrierName')
      ..remove('subscriptionInfoNumber'); // phone number: not shown on screen

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sim.carrierName ?? 'Unknown carrier',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            KeyValueGrid(values: details),
          ],
        ),
      ),
    );
  }
}
