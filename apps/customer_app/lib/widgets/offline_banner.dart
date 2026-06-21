import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import '../core/theme.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final syncProv = context.watch<SyncProvider>();

    if (syncProv.isOnline && !syncProv.hasPending) {
      return const SizedBox.shrink();
    }

    return Material(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: syncProv.isOnline ? AppTheme.accentGreen : AppTheme.errorRed,
        child: Row(
          children: [
            Icon(
              syncProv.isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                syncProv.isOnline
                    ? '${syncProv.pendingCount} إجراءات معلقة'
                    : 'لا يوجد اتصال بالإنترنت',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            if (syncProv.hasPending && syncProv.isOnline)
              GestureDetector(
                onTap: () => syncProv.triggerSync(),
                child: const Text(
                  'مزامنة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
