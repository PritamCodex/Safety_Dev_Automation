import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cooperative_navigation_safety/src/core/theme/app_theme.dart';
import 'package:cooperative_navigation_safety/src/providers/app_providers.dart';

class ControlPanel extends ConsumerWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final systemCoordinator = ref.watch(systemCoordinatorProvider);
    
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Controls',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Start/Stop Button
          ElevatedButton.icon(
            onPressed: () {
              if (appState.isSystemRunning) {
                systemCoordinator.stopSystem();
              } else {
                systemCoordinator.startSystem();
              }
            },
            icon: Icon(
              appState.isSystemRunning ? Icons.stop : Icons.play_arrow,
              size: 20,
            ),
            label: Text(
              appState.isSystemRunning ? 'Stop System' : 'Start System',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: appState.isSystemRunning 
                  ? AppTheme.alertRed 
                  : AppTheme.accentTeal,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Mode Selection
          Text(
            'Operating Mode',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              _buildModeButton(
                context,
                'Normal',
                appState.mode == 'normal',
                () => ref.read(appStateProvider.notifier).setMode('normal'),
              ),
              const SizedBox(width: 8),
              _buildModeButton(
                context,
                'Anchor',
                appState.mode == 'anchor',
                () => ref.read(appStateProvider.notifier).setMode('anchor'),
              ),
              const SizedBox(width: 8),
              _buildModeButton(
                context,
                'Emergency',
                appState.mode == 'emergency',
                () => ref.read(appStateProvider.notifier).setMode('emergency'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Report Incident Button
          OutlinedButton.icon(
            onPressed: () {
              _showReportIncidentDialog(context, ref);
            },
            icon: const Icon(Icons.report, size: 20),
            label: const Text('Report Incident'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.alertOrange,
              side: BorderSide(color: AppTheme.alertOrange),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected 
              ? AppTheme.accentTeal.withValues(alpha: 0.2)
              : Colors.transparent,
          side: BorderSide(
            color: isSelected 
                ? AppTheme.accentTeal 
                : AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.accentTeal : AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showReportIncidentDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report Incident'),
          content: const Text(
            'This will immediately broadcast an emergency beacon to all nearby devices. '
            'Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Trigger emergency broadcast
                ref.read(appStateProvider.notifier).setMode('emergency');
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.alertRed,
              ),
              child: const Text('Report Emergency'),
            ),
          ],
        );
      },
    );
  }
}