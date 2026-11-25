import 'package:material_ui/material_ui.dart';

/// Flattens a model's `toJson()` output into `label: value` pairs laid out in a wrapping grid.
///
/// Nested objects (band, signal, network) are flattened with their key as a prefix, so every
/// field the plugin delivers is visible without a hand-written widget per technology.
class KeyValueGrid extends StatelessWidget {
  const KeyValueGrid({super.key, required this.values});

  final Map<String, dynamic> values;

  static Map<String, dynamic> flatten(
    Map<String, dynamic> json, [
    String prefix = '',
  ]) {
    final result = <String, dynamic>{};
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result.addAll(flatten(value, '$prefix$key.'));
      } else {
        result['$prefix$key'] = value;
      }
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        for (final entry in flatten(values).entries)
          if (entry.value != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.key, style: labelStyle),
                Text('${entry.value}', style: theme.textTheme.bodyMedium),
              ],
            ),
      ],
    );
  }
}
