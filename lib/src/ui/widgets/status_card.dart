import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cooperative_navigation_safety/src/core/theme/app_theme.dart';
import 'package:cooperative_navigation_safety/src/providers/app_providers.dart';

class StatusCard extends ConsumerWidget {
  const StatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final peerCount = ref.watch(peerBeaconsProvider).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentTeal.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Status',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            'Service',
            appState.isSystemRunning ? 'Active' : 'Stopped',
            appState.isSystemRunning ? AppTheme.alertGreen : AppTheme.textSecondary,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Mode',
            appState.mode,
            AppTheme.accentTeal,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Nearby Devices',
            peerCount.toString(),
            peerCount > 0 ? AppTheme.alertGreen : AppTheme.textSecondary,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Permissions',
            appState.hasPermissions ? 'Granted' : 'Required',
            appState.hasPermissions ? AppTheme.alertGreen : AppTheme.alertOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: valueColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}