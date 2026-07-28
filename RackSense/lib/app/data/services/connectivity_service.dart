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
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      _subscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (_) => _setOffline(),
      );
    } on Object catch (_) {
      _setOffline();
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected.value;
    _isConnected.value = results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.mobile,
    );
    update();

    if (wasConnected != _isConnected.value) {
      _connectionController.add(_isConnected.value);
      onConnectionChanged?.call(_isConnected.value);
    }
    print('Connection Updated, isConnected => $isConnected');
  }

  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } on Object catch (_) {
      _setOffline();
    }
    return _isConnected.value;
  }

  void _setOffline() {
    _updateConnectionStatus(const [ConnectivityResult.none]);
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
