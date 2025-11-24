import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cooperative_navigation_safety/src/core/theme/app_theme.dart';
import 'package:cooperative_navigation_safety/src/core/models/collision_alert.dart';
import 'package:cooperative_navigation_safety/src/providers/app_providers.dart';

class AlertBanner extends ConsumerWidget {
  const AlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final criticalAlert = ref.watch(criticalAlertProvider);
    
    if (criticalAlert == null || !criticalAlert.isActive) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 60,
      decoration: BoxDecoration(
        color: criticalAlert.level.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: criticalAlert.level.color.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              _getAlertIcon(criticalAlert.level),
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    criticalAlert.level.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    criticalAlert.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (criticalAlert.level == AlertLevel.red)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getAlertIcon(AlertLevel level) {
    switch (level) {
      case AlertLevel.green:
        return Icons.check_circle;
      case AlertLevel.yellow:
        return Icons.warning;
      case AlertLevel.orange:
        return Icons.error;
      case AlertLevel.red:
        return Icons.dangerous;
    }
  }
}