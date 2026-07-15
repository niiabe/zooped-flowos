import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/update_service.dart';

/// Wraps the app UI and performs a silent update check shortly after launch.
/// If a newer (non-skipped) release is found on GitHub, it prompts the user.
class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  final UpdateService _service = UpdateService();
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _silentCheck());
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _silentCheck() async {
    if (_checked) return;
    _checked = true;
    try {
      final update = await _service.checkForUpdate(respectSkip: true);
      if (update == null || !mounted) return;
      await _showUpdateDialog(update);
    } catch (_) {
      // Silent: never interrupt launch if the check fails.
    }
  }

  Future<void> _showUpdateDialog(UpdateInfo update) async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.system_update, size: 32),
          title: Text('Update available: v${update.version}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('A new version of ZooPed is available.'),
              if (update.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  update.releaseNotes.length > 240
                      ? '${update.releaseNotes.substring(0, 240)}...'
                      : update.releaseNotes,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('skip'),
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('later'),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop('update'),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    switch (action) {
      case 'update':
        GoRouter.of(context).push('/settings/update');
        break;
      case 'skip':
        await _service.skipVersion(update.version);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
