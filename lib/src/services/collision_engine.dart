import 'dart:math' as math;
import 'package:cooperative_navigation_safety/src/core/models/beacon_packet.dart';
import 'package:cooperative_navigation_safety/src/core/models/collision_alert.dart';

class CollisionEngine {
  static const double _earthRadius = 6371000; // meters
  static const double _safetyDistance = 10.0; // meters
  static const double _warningDistance = 5.0; // meters
  static const double _dangerDistance = 2.0; // meters
  
  static const double _cautionTTC = 30.0; // seconds
  static const double _warningTTC = 10.0; // seconds
  static const double _emergencyTTC = 5.0; // seconds
  
  CollisionAlert? calculateCollisionRisk(
    BeaconPacket localBeacon,
    BeaconPacket peerBeacon,
  ) {
    final timeDelta = peerBeacon.timestamp.difference(localBeacon.timestamp).inMilliseconds.abs();
    
    // Skip stale data (older than 2 seconds)
    if (timeDelta > 2000) {
      return null;
    }
    
    // Calculate relative position
    final relativeDistance = _calculateDistance(
      localBeacon.latitude, localBeacon.longitude,
      peerBeacon.latitude, peerBeacon.longitude,
    );
    
    // Calculate relative velocity
    final relativeVelocityX = peerBeacon.velocityX - localBeacon.velocityX;
    final relativeVelocityY = peerBeacon.velocityY - localBeacon.velocityY;
    final closingSpeed = math.sqrt(relativeVelocityX * relativeVelocityX + relativeVelocityY * relativeVelocityY);
    
    // Calculate bearing and heading difference
    final bearingToPeer = _calculateBearing(
      localBeacon.latitude, localBeacon.longitude,
      peerBeacon.latitude, peerBeacon.longitude,
    );
    // final headingDiff = (peerBeacon.heading - localBeacon.heading + 360) % 360; // Unused
    
    // Calculate lateral and longitudinal components
    final lateralDelta = relativeDistance * math.sin((bearingToPeer - localBeacon.heading) * math.pi / 180);
    final longitudinalDelta = relativeDistance * math.cos((bearingToPeer - localBeacon.heading) * math.pi / 180);
    
    // Calculate time to collision (TTC)
    double timeToCollision = double.infinity;
    if (closingSpeed > 0.1) { // Minimum speed threshold
      timeToCollision = relativeDistance / closingSpeed;
    }
    
    // Calculate collision probability
    final collisionProbability = _calculateCollisionProbability(
      relativeDistance,
      closingSpeed,
      timeToCollision,
      localBeacon.accuracy,
      peerBeacon.accuracy,
    );
    
    // Determine alert level
    final alertLevel = _determineAlertLevel(
      relativeDistance,
      timeToCollision,
      collisionProbability,
    );
    
    return CollisionAlert(
      peerId: peerBeacon.ephemeralId,
      level: alertLevel,
      relativeDistance: relativeDistance,
      closingSpeed: closingSpeed,
      timeToCollision: timeToCollision,
      lateralDelta: lateralDelta,
      longitudinalDelta: longitudinalDelta,
      probability: collisionProbability,
    );
  }
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadius * c;
  }
  
  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * math.pi / 180;
    final lat1Rad = lat1 * math.pi / 180;
    final lat2Rad = lat2 * math.pi / 180;
    
    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);
    
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }
  
  double _calculateCollisionProbability(
    double distance,
    double closingSpeed,
    double ttc,
    double localAccuracy,
    double peerAccuracy,
  ) {
    // Base probability on distance
    double distanceFactor = 1.0;
    if (distance < _dangerDistance) {
      distanceFactor = 0.9;
    } else if (distance < _warningDistance) {
      distanceFactor = 0.7;
    } else if (distance < _safetyDistance) {
      distanceFactor = 0.4;
    } else {
      distanceFactor = 0.1;
    }
    
    // Factor in closing speed
    double speedFactor = math.min(closingSpeed / 20.0, 1.0);
    
    // Factor in time to collision
    double ttcFactor = 0.0;
    if (ttc < _emergencyTTC) {
      ttcFactor = 0.9;
    } else if (ttc < _warningTTC) {
      ttcFactor = 0.7;
    } else if (ttc < _cautionTTC) {
      ttcFactor = 0.4;
    }
    
    // Factor in GPS accuracy
    double accuracyFactor = math.max(localAccuracy, peerAccuracy) / 10.0;
    accuracyFactor = math.min(accuracyFactor, 1.0);
    
    // Combine factors
    return distanceFactor * speedFactor * ttcFactor * (1 - accuracyFactor * 0.5);
  }
  
  AlertLevel _determineAlertLevel(double distance, double ttc, double probability) {
    if (distance > _safetyDistance && ttc > _cautionTTC) {
      return AlertLevel.green;
    }
    
    if (ttc <= _emergencyTTC || distance <= _dangerDistance || probability > 0.8) {
      return AlertLevel.red;
    }
    
    if (ttc <= _warningTTC || distance <= _warningDistance || probability > 0.6) {
      return AlertLevel.orange;
    }
    
    if (ttc <= _cautionTTC || distance <= _safetyDistance || probability > 0.3) {
      return AlertLevel.yellow;
    }
    
    return AlertLevel.green;
  }
  
  List<CollisionAlert> processMultiplePeers(
    BeaconPacket localBeacon,
    List<BeaconPacket> peerBeacons,
  ) {
    final alerts = <CollisionAlert>[];
    
    for (final peerBeacon in peerBeacons) {
      if (peerBeacon.ephemeralId == localBeacon.ephemeralId) continue;
      
      final alert = calculateCollisionRisk(localBeacon, peerBeacon);
      if (alert != null) {
        alerts.add(alert);
      }
    }
    
    // Sort by severity (most critical first)
    alerts.sort((a, b) {
      if (a.level.index != b.level.index) {
        return b.level.index.compareTo(a.level.index);
      }
      return a.timeToCollision.compareTo(b.timeToCollision);
    });
    
    return alerts;
  }
}