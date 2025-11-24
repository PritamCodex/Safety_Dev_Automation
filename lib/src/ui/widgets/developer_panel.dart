import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cooperative_navigation_safety/src/core/theme/app_theme.dart';
import 'package:cooperative_navigation_safety/src/providers/app_providers.dart';

class DeveloperPanel extends ConsumerWidget {
  const DeveloperPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorData = ref.watch(sensorDataStreamProvider);
    final currentLocation = ref.watch(currentLocationProvider);
    final peerBeacons = ref.watch(peerBeaconsProvider);
    final alerts = ref.watch(collisionAlertsProvider);
    final appState = ref.watch(appStateProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.alertYellow.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.developer_mode, color: AppTheme.alertYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'DEVELOPER MODE',
                style: TextStyle(
                  color: AppTheme.alertYellow,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // System Status
          _buildSection('System Status', [
            _buildDataRow('Service Running', appState.isSystemRunning ? '✓ YES' : '✗ NO'),
            _buildDataRow('Permissions', appState.hasPermissions ? '✓ Granted' : '✗ Denied'),
            _buildDataRow('Mode', appState.mode),
            _buildDataRow('Error', appState.error ?? 'None'),
          ]),
          
          const SizedBox(height: 12),
          
          // Sensor Data
          _buildSection('Sensor Data', [
            sensorData.when(
              data: (data) => Column(
                children: [
                  _buildDataRow('Location', '${data.latitude?.toStringAsFixed(6) ?? 'N/A'}, ${data.longitude?.toStringAsFixed(6) ?? 'N/A'}'),
                  _buildDataRow('Speed', '${data.speed?.toStringAsFixed(2) ?? 'N/A'} m/s'),
                  _buildDataRow('Heading', '${data.heading?.toStringAsFixed(1) ?? 'N/A'}°'),
                  _buildDataRow('Accuracy', '${data.accuracy?.toStringAsFixed(1) ?? 'N/A'}m'),
                  _buildDataRow('Accel', '${data.totalAcceleration.toStringAsFixed(2)} m/s²'),
                  _buildDataRow('Gyro', '${data.totalGyroscope.toStringAsFixed(2)} rad/s'),
                ],
              ),
              loading: () => _buildDataRow('Status', 'Loading...'),
              error: (e, _) => _buildDataRow('Error', e.toString()),
            ),
          ]),
          
          const SizedBox(height: 12),
          
          // Current Beacon
          _buildSection('Current Beacon', [
            if (currentLocation != null) ...[
              _buildDataRow('Type', currentLocation.type),
              _buildDataRow('ID', currentLocation.ephemeralId.substring(0, 8) + '...'),
              _buildDataRow('Lat/Lng', '${currentLocation.latitude.toStringAsFixed(6)}, ${currentLocation.longitude.toStringAsFixed(6)}'),
              _buildDataRow('Velocity', '${currentLocation.velocityX.toStringAsFixed(2)}, ${currentLocation.velocityY.toStringAsFixed(2)}'),
            ] else
              _buildDataRow('Status', 'No beacon data'),
          ]),
          
          const SizedBox(height: 12),
          
          // Nearby Peers
          _buildSection('Nearby Peers (${peerBeacons.length})', [
            if (peerBeacons.isEmpty)
              _buildDataRow('Status', 'No peers detected')
            else
              ...peerBeacons.take(3).map((peer) => 
                _buildDataRow(
                  peer.ephemeralId.substring(0, 8),
                  '${peer.latitude.toStringAsFixed(4)}, ${peer.longitude.toStringAsFixed(4)}',
                ),
              ),
          ]),
          
          const SizedBox(height: 12),
          
          // Collision Alerts
          _buildSection('Collision Alerts (${alerts.length})', [
            if (alerts.isEmpty)
              _buildDataRow('Status', 'No alerts')
            else
              ...alerts.take(3).map((alert) => 
                _buildDataRow(
                  alert.peerId.substring(0, 8),
                  '${alert.relativeDistance.toStringAsFixed(1)}m @ ${alert.timeToCollision.toStringAsFixed(1)}s',
                  color: alert.level.color,
                ),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.accentTeal,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDataRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: color ?? AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
