import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:uuid/uuid.dart';
import 'package:cooperative_navigation_safety/src/core/models/beacon_packet.dart';
import 'package:location/location.dart';

class NearbyService {
  static const String _serviceId = 'cooperative_navigation_safety';
  static const Strategy _strategy = Strategy.P2P_CLUSTER;
  static const MethodChannel _channel = MethodChannel('cooperative_navigation_safety/main');
  
  final Nearby _nearby = Nearby();
  final String _deviceId = const Uuid().v4();
  
  final StreamController<BeaconPacket> _beaconController = StreamController<BeaconPacket>.broadcast();
  final StreamController<String> _peerController = StreamController<String>.broadcast();
  final StreamController<String> _connectionController = StreamController<String>.broadcast();
  
  Stream<BeaconPacket> get beaconStream => _beaconController.stream;
  Stream<String> get peerStream => _peerController.stream;
  Stream<String> get connectionStream => _connectionController.stream;
  
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  final Set<String> _connectedPeers = {};
  Timer? _beaconTimer;
  
  String get deviceId => _deviceId;
  
  Future<void> initialize() async {
    try {
      // 1. Request Android 12+ Bluetooth & Nearby Permissions via Platform Channel
      try {
        await _channel.invokeMethod('requestPermissions');
      } catch (e) {
        print('Failed to request permissions via channel: $e');
      }

      // 2. Ensure Location Service is enabled (using Location package)
      final location = Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          print('Warning: Location service not enabled for Nearby');
        }
      }
      
    } catch (e) {
      print('Nearby initialization error: $e');
    }
  }
  
  void startNearby() {
    startAdvertising();
    startDiscovery();
  }
  
  void stopNearby() {
    stopAdvertising();
    stopDiscovery();
    stopBeaconTimer();
    disconnectFromAllPeers();
  }
  
  void startAdvertising() {
    if (_isAdvertising) return;
    
    _nearby.startAdvertising(
      _deviceId,
      _strategy,
      serviceId: _serviceId,
      onConnectionInitiated: (String endpointId, ConnectionInfo info) {
        _nearby.acceptConnection(
          endpointId,
          onPayLoadRecieved: (String endpointId, Payload payload) {
            _handlePayload(endpointId, payload);
          },
          onPayloadTransferUpdate: (String endpointId, PayloadTransferUpdate update) {
            // Handle transfer updates if needed
          },
        );
      },
      onConnectionResult: (String endpointId, Status status) {
        if (status == Status.CONNECTED) {
          _connectedPeers.add(endpointId);
          _connectionController.add('Connected to $endpointId');
        }
      },
      onDisconnected: (String endpointId) {
        _connectedPeers.remove(endpointId);
        _connectionController.add('Disconnected from $endpointId');
      },
    );
    
    _isAdvertising = true;
  }
  
  void stopAdvertising() {
    if (!_isAdvertising) return;
    _nearby.stopAdvertising();
    _isAdvertising = false;
  }
  
  void startDiscovery() {
    if (_isDiscovering) return;
    
    _nearby.startDiscovery(
      _deviceId,
      _strategy,
      serviceId: _serviceId,
      onEndpointFound: (String endpointId, String userNickName, String serviceId) {
        _peerController.add('Found peer: $userNickName');
        _nearby.requestConnection(
          userNickName,
          endpointId,
          onConnectionInitiated: (String endpointId, ConnectionInfo info) {
            _nearby.acceptConnection(
              endpointId,
              onPayLoadRecieved: (String endpointId, Payload payload) {
                _handlePayload(endpointId, payload);
              },
              onPayloadTransferUpdate: (String endpointId, PayloadTransferUpdate update) {
                // Handle transfer updates if needed
              },
            );
          },
          onConnectionResult: (String endpointId, Status status) {
            if (status == Status.CONNECTED) {
              _connectedPeers.add(endpointId);
              _connectionController.add('Connected to $endpointId');
            }
          },
          onDisconnected: (String endpointId) {
            _connectedPeers.remove(endpointId);
            _connectionController.add('Disconnected from $endpointId');
          },
        );
      },
      onEndpointLost: (endpointId) {
        _peerController.add('Lost peer: $endpointId');
      },
    );
    
    _isDiscovering = true;
  }
  
  void stopDiscovery() {
    if (!_isDiscovering) return;
    _nearby.stopDiscovery();
    _isDiscovering = false;
  }
  
  void startBeaconTimer(BeaconPacket Function() beaconGenerator) {
    stopBeaconTimer();
    
    _beaconTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      // Always generate and broadcast beacons, even if no peers yet
      // This ensures beacons are ready when peers connect
      final beacon = beaconGenerator();
      broadcastBeacon(beacon);
    });
  }
  
  void stopBeaconTimer() {
    _beaconTimer?.cancel();
    _beaconTimer = null;
  }
  
  void broadcastBeacon(BeaconPacket beacon) {
    final bytes = utf8.encode(jsonEncode(beacon.toJson()));
    
    for (final peerId in _connectedPeers) {
      _nearby.sendBytesPayload(peerId, bytes);
    }
  }
  
  void _handlePayload(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      try {
        final data = utf8.decode(payload.bytes!);
        final json = jsonDecode(data);
        
        if (json['type'] == 'beacon') {
          final beacon =
              BeaconPacket.fromJson(json).copyWith(receivedAt: DateTime.now());
          _beaconController.add(beacon);
        }
      } catch (e) {
        print('Error handling payload: $e');
      }
    }
  }
  
  void disconnectFromAllPeers() {
    for (final peerId in _connectedPeers) {
      _nearby.disconnectFromEndpoint(peerId);
    }
    _connectedPeers.clear();
  }
  
  void dispose() {
    stopNearby();
    _beaconController.close();
    _peerController.close();
    _connectionController.close();
  }
}