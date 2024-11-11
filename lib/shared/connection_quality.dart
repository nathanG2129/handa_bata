import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  
  // Private constructor
  ConnectionManager._internal() {
    startMonitoring();
  }

  // Shared connection monitoring
  final StreamController<ConnectionQuality> _qualityController = 
      StreamController<ConnectionQuality>.broadcast();
  
  Stream<ConnectionQuality> get connectionQuality => _qualityController.stream;
  
  Timer? _monitoringTimer;
  
  Future<ConnectionQuality> checkConnectionQuality() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return ConnectionQuality.OFFLINE;
      }
      
      // Check latency
      final start = DateTime.now();
      // Add your latency check here
      final latency = DateTime.now().difference(start);
      
      if (latency.inMilliseconds < 100) return ConnectionQuality.EXCELLENT;
      if (latency.inMilliseconds < 300) return ConnectionQuality.GOOD;
      return ConnectionQuality.POOR;
    } catch (e) {
      print('Error checking connection quality: $e');
      return ConnectionQuality.OFFLINE;
    }
  }

  void startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final quality = await checkConnectionQuality();
      _qualityController.add(quality);
    });
  }

  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }
} 