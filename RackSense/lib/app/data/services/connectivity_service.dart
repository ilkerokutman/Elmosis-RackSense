import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxController {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final RxBool _isConnected = false.obs;
  RxBool get isConnectedRx => _isConnected;
  bool get isConnected => _isConnected.value;

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  void Function(bool isConnected)? onConnectionChanged;

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results);
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected.value = results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.mobile,
    );
    update();

    if (wasConnected != _isConnected) {
      _connectionController.add(_isConnected.value);
      onConnectionChanged?.call(_isConnected.value);
    }
  }

  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
    return _isConnected.value;
  }

  Future<bool> hasInternetAccess() async {
    if (!_isConnected.value) return false;

    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _connectionController.close();
    super.dispose();
  }
}
