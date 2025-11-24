import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cooperative_navigation_safety/src/core/theme/app_theme.dart';
import 'package:cooperative_navigation_safety/src/core/models/collision_alert.dart';
import 'package:cooperative_navigation_safety/src/providers/app_providers.dart';

class RadarWidget extends ConsumerStatefulWidget {
  const RadarWidget({super.key});

  @override
  ConsumerState<RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends ConsumerState<RadarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(collisionAlertsProvider);
    final criticalAlert = ref.watch(criticalAlertProvider);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentTeal.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Animated background rings
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: RadarPainter(
                      animationValue: _controller.value,
                      alerts: alerts,
                      criticalAlert: criticalAlert,
                    ),
                  );
                },
              ),
            ),
            
            // Center user indicator
            Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentTeal.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            
            // Peer indicators
            ..._buildPeerIndicators(alerts),
            
            // Range indicators
            _buildRangeIndicators(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPeerIndicators(List<CollisionAlert> alerts) {
    return alerts.map((alert) {
      final angle = math.Random().nextDouble() * 2 * math.pi;
      final distance = math.min(alert.relativeDistance / 50, 1.0); // Normalize to 0-1
      
      final x = math.cos(angle) * distance * 120;
      final y = math.sin(angle) * distance * 120;
      
      return Positioned(
        left: 150 + x - 8,
        top: 150 + y - 8,
        child: _buildPeerIndicator(alert),
      );
    }).toList();
  }

  Widget _buildPeerIndicator(CollisionAlert alert) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: alert.level.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: alert.level.color.withValues(alpha: 0.6),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildRangeIndicators() {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Range: 0-50m',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            'Update: 60 FPS',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final double animationValue;
  final List<CollisionAlert> alerts;
  final CollisionAlert? criticalAlert;

  RadarPainter({
    required this.animationValue,
    required this.alerts,
    this.criticalAlert,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw concentric circles
    for (int i = 1; i <= 4; i++) {
      paint.color = AppTheme.accentTeal.withValues(alpha: 0.2);
      canvas.drawCircle(center, i * 30, paint);
    }

    // Draw cross lines
    paint.color = AppTheme.accentTeal.withValues(alpha: 0.15);
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      paint,
    );

    // Draw rotating sweep line
    final sweepAngle = animationValue * 2 * math.pi;
    final sweepPaint = Paint()
      ..color = AppTheme.accentTeal.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepEnd = Offset(
      center.dx + math.cos(sweepAngle) * 120,
      center.dy + math.sin(sweepAngle) * 120,
    );
    canvas.drawLine(center, sweepEnd, sweepPaint);

    // Draw sweep gradient
    final gradientPaint = Paint()
      ..shader = ui.Gradient.sweep(
        center,
        [
          AppTheme.accentTeal.withValues(alpha: 0.3),
          AppTheme.accentTeal.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        [0.0, 0.3, 1.0],
        TileMode.clamp,
        sweepAngle - math.pi / 4,
        sweepAngle + math.pi / 4,
      );

    canvas.drawCircle(center, 120, gradientPaint);

    // Draw critical alert overlay
    if (criticalAlert != null && criticalAlert!.level.isCritical) {
      final alertPaint = Paint()
        ..color = criticalAlert!.level.color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(center, 140, alertPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}