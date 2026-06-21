import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import '../core/theme.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final syncProvider = context.watch<SyncProvider>();

    if (syncProvider.isOnline && !syncProvider.hasPending) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: syncProvider.isOnline
          ? AppTheme.warningOrange
          : AppTheme.errorRed,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        bottom: 8,
        left: 16,
        right: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            syncProvider.isOnline ? Icons.sync : Icons.wifi_off_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            syncProvider.isOnline
                ? 'تزامن البيانات... (${syncProvider.pendingCount})'
                : 'لا يوجد اتصال بالإنترنت',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (syncProvider.isOnline && syncProvider.hasPending) ...[
            const Spacer(),
            GestureDetector(
              onTap: () => syncProvider.triggerSync(),
              child: syncProvider.isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.sync, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
