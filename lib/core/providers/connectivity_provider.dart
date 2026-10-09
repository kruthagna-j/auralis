import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isConnected = false;
  bool _isInitialized = false;
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];

  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
  List<ConnectivityResult> get connectionStatus => _connectionStatus;
  bool get hasInternet =>
      _isConnected &&
      _connectionStatus.any(
        (result) =>
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.ethernet,
      );

  bool get isWifiConnected =>
      _isConnected && _connectionStatus.contains(ConnectivityResult.wifi);

  String get connectionType {
    if (!_isConnected) return 'No Connection';
    if (_connectionStatus.contains(ConnectivityResult.wifi)) return 'WiFi';
    if (_connectionStatus.contains(ConnectivityResult.mobile))
      return 'Mobile Data';
    if (_connectionStatus.contains(ConnectivityResult.ethernet))
      return 'Ethernet';
    return 'Unknown';
  }

  ConnectivityProvider() {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      final List<ConnectivityResult> result = await _connectivity
          .checkConnectivity();
      await _updateConnectionStatus(result);

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          debugPrint('Connectivity subscription error: $error');
        },
      );

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize connectivity: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    _connectionStatus = result;

    final bool wasConnected = _isConnected;
    _isConnected = result.any(
      (connectivity) => connectivity != ConnectivityResult.none,
    );

    if (_isConnected) {
      _isConnected = await _hasInternetAccess();
    }

    if (wasConnected != _isConnected) {
      debugPrint('Connectivity changed: $_isConnected (${connectionType})');
      notifyListeners();

      if (_isConnected && !wasConnected) {
        _onConnectedToInternet();
      } else if (!_isConnected && wasConnected) {
        _onDisconnectedFromInternet();
      }
    }
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.any(
        (connectivity) =>
            connectivity == ConnectivityResult.wifi ||
            connectivity == ConnectivityResult.mobile ||
            connectivity == ConnectivityResult.ethernet,
      );
    } catch (e) {
      debugPrint('Internet access check failed: $e');
      return false;
    }
  }

  void _onConnectedToInternet() {
    debugPrint('Connected to internet - can initialize network services');
  }

  void _onDisconnectedFromInternet() {
    debugPrint('Disconnected from internet - switching to offline mode');
  }

  Future<void> refreshConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Failed to refresh connectivity: $e');
    }
  }

  bool canPerformNetworkOperations() {
    return _isInitialized && _isConnected && hasInternet;
  }

  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (canPerformNetworkOperations()) return true;

    final completer = Completer<bool>();
    late StreamSubscription subscription;

    subscription = _connectivity.onConnectivityChanged.listen((result) async {
      await _updateConnectionStatus(result);
      if (canPerformNetworkOperations()) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    return completer.future;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
