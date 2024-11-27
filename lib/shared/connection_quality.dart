import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

// Central definition for connection quality
enum ConnectionQuality {
  OFFLINE,
  POOR,
  GOOD,
  EXCELLENT
}

class ConnectionManager {
  static final ConnectionManager _instance = ConnectionManager._internal();
  factory ConnectionManager() => _instance;
  
  final StreamController<ConnectionQuality> _qualityController = 
      StreamController<ConnectionQuality>.broadcast();
  
  Stream<ConnectionQuality> get connectionQuality => _qualityController.stream;
  
  Timer? _monitoringTimer;
  ConnectionQuality _lastKnownQuality = ConnectionQuality.GOOD;
  
  // Add Connectivity subscription
  StreamSubscription? _connectivitySubscription;
  
  ConnectionManager._internal() {
    _initializeConnectivityListener();
  }

  void _initializeConnectivityListener() {
    // Listen to immediate connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) async {
      if (result == ConnectivityResult.none) {
        _lastKnownQuality = ConnectionQuality.OFFLINE;
        _qualityController.add(ConnectionQuality.OFFLINE);
      } else {
        // Only check quality if we're online
        final quality = await checkConnectionQuality();
        _lastKnownQuality = quality;
        _qualityController.add(quality);
      }
    });

    // Initial check
    _performInitialCheck();
    
    // Start periodic monitoring for quality changes
    startMonitoring();
  }

  Future<void> _performInitialCheck() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      _lastKnownQuality = ConnectionQuality.OFFLINE;
      _qualityController.add(ConnectionQuality.OFFLINE);
    } else {
      final quality = await checkConnectionQuality();
      _lastKnownQuality = quality;
      _qualityController.add(quality);
    }
  }

  Future<ConnectionQuality> checkConnectionQuality() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return ConnectionQuality.OFFLINE;
      }
      
      // Quick connection check
      final start = DateTime.now();
      try {
        await InternetAddress.lookup('google.com');
        final duration = DateTime.now().difference(start);
        
        if (duration.inMilliseconds < 100) return ConnectionQuality.EXCELLENT;
        if (duration.inMilliseconds < 300) return ConnectionQuality.GOOD;
        return ConnectionQuality.POOR;
      } catch (_) {
        return ConnectionQuality.OFFLINE;
      }
    } catch (e) {
      return ConnectionQuality.OFFLINE;
    }
  }

  void startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final quality = await checkConnectionQuality();
      if (quality != _lastKnownQuality) {
        _lastKnownQuality = quality;
        _qualityController.add(quality);
      }
    });
  }

  void dispose() {
    _monitoringTimer?.cancel();
    _connectivitySubscription?.cancel();
    _qualityController.close();
  }
} 