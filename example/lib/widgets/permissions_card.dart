import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

/// Shows the state of the runtime permissions the plugin depends on and lets the tester
/// grant them, so every permission state can be tried on a device or emulator.
class PermissionsCard extends StatelessWidget {
  const PermissionsCard({
    super.key,
    required this.statuses,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final Map<Permission, PermissionStatus> statuses;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  static String label(Permission permission) {
    if (permission == Permission.locationWhenInUse) {
      return 'Location (ACCESS_FINE_LOCATION)';
    }
    if (permission == Permission.phone) return 'Phone (READ_PHONE_STATE)';
    return permission.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allGranted =
        statuses.isNotEmpty && statuses.values.every((s) => s.isGranted);
    final permanentlyDenied = statuses.values.any((s) => s.isPermanentlyDenied);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Permissions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final entry in statuses.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      entry.value.isGranted ? Icons.check_circle : Icons.cancel,
                      size: 18,
                      color: entry.value.isGranted
                          ? scheme.primary
                          : scheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(label(entry.key))),
                    Text(entry.value.name),
                  ],
                ),
              ),
            if (!allGranted) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    key: const Key('request_permissions'),
                    onPressed: onRequest,
                    child: const Text('Request permissions'),
                  ),
                  if (permanentlyDenied)
                    OutlinedButton(
                      onPressed: onOpenSettings,
                      child: const Text('Open app settings'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
