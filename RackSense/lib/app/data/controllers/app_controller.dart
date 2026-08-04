import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dart_periphery/dart_periphery.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/core/constants/serial.dart';
import 'package:rack_sense/app/core/routes/routes.dart';
import 'package:rack_sense/app/core/utils/common_utils.dart';
import 'package:rack_sense/app/data/models/ac_unit_state.dart';
import 'package:rack_sense/app/data/models/app_settings.dart';
import 'package:rack_sense/app/data/models/mainboard_input.dart';
import 'package:rack_sense/app/data/models/pin_state.dart';
import 'package:rack_sense/app/data/repositories/telemetry_repository.dart';
import 'package:rack_sense/app/data/services/connectivity_service.dart';
import 'package:rack_sense/app/data/services/serial_service.dart';
import 'package:rack_sense/app/data/services/settings_service.dart';

const List<int> eightInts = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08];
const List<int> sixInts = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06];
const List<int> fourInts = [0x01, 0x02, 0x03, 0x04];
const int mainboardId = 0x00;
const int one = 0x01;
const int maxConsecutiveCommunicationTimeouts = 3;
const Duration disconnectedUnitProbeInterval = Duration(minutes: 10);
const Duration temperatureSampleInterval = Duration(seconds: 30);

class AppController extends GetxController {
  late final ConnectivityService _connectivityService;
  late final SerialService _serialService;
  late final TelemetryRepository _telemetryRepository;
  late final SettingsService _settingsService;
  GPIO? uartModeTx;
  GPIO? btn1;
  GPIO? btn2;
  GPIO? btn3;
  GPIO? btn4;
  GPIO? outPinSER;
  GPIO? outPinSRCLK;
  GPIO? outPinRCLK;
  GPIO? buzzer;
  GPIO? in1;
  GPIO? in2;
  GPIO? in3;
  GPIO? in4;
  GPIO? in5;
  GPIO? in6;
  GPIO? in7;
  GPIO? in8;
  GPIO? txEnablePin;
  SPI? spiAdc;

  StreamSubscription<Uint8List>? _serialMessageSubscription;

  final RxMap<int, AcUnitState> _units = <int, AcUnitState>{
    SerialKeys.device1: const AcUnitState(
      deviceId: SerialKeys.device1,
      isConnected: false,
    ),
    SerialKeys.device2: const AcUnitState(
      deviceId: SerialKeys.device2,
      isConnected: false,
    ),
  }.obs;
  final RxBool _isAutoMode = false.obs;
  final RxInt _desiredTemperature = 23.obs;
  final RxInt _inputRevision = 0.obs;
  final RxBool _cabinetShutdownBlocked = false.obs;
  final Set<int> _handledFailureDevices = <int>{};
  final Map<int, int> _communicationTimeoutCounts = <int, int>{};
  final Map<int, int> _skipPollCounts = <int, int>{};
  bool _isBuzzerPatternRunning = false;

  DateTime? _nextAutoSwitchAt;
  final Map<int, DateTime> _lastTemperatureSampleAt = {};

  Map<int, AcUnitState> get units => Map.unmodifiable(_units);
  bool get isAutoMode => _isAutoMode.value;
  int get desiredTemperature => _desiredTemperature.value;
  RxInt get inputRevisionRx => _inputRevision;
  bool get isCabinetShutdownBlocked => _cabinetShutdownBlocked.value;
  DateTime? get nextAutoSwitchAt => _nextAutoSwitchAt;
  double? get rackTemperature {
    final connectedUnits = units.values.where(
      (unit) => unit.isConnected && unit.ntc1 != null,
    );
    final unit =
        connectedUnits.where((unit) => unit.isRunning).firstOrNull ??
        connectedUnits.where((unit) => unit.lastResponseAt != null).firstOrNull;
    return unit?.ntc1?.toDouble();
  }

  AcUnitState unitFor(int deviceId) =>
      _units[deviceId] ?? AcUnitState(deviceId: deviceId);

  bool canTurnOn(int deviceId) {
    if (isCabinetShutdownBlocked) return false;
    final unit = unitFor(deviceId);
    if (!unit.isConnected) return false;
    return unit.lastTurnedOffAt == null ||
        DateTime.now().difference(unit.lastTurnedOffAt!) >=
            const Duration(seconds: 15);
  }

  bool canTurnOff(int deviceId) {
    final unit = unitFor(deviceId);
    if (!unit.isConnected) return false;
    return unit.lastTurnedOnAt == null ||
        DateTime.now().difference(unit.lastTurnedOnAt!) >=
            const Duration(seconds: 15);
  }

  int cooldownSecondsRemaining(int deviceId, {required bool turningOn}) {
    final timestamp = turningOn
        ? unitFor(deviceId).lastTurnedOffAt
        : unitFor(deviceId).lastTurnedOnAt;
    if (timestamp == null) return 0;
    final remaining =
        const Duration(seconds: 15) - DateTime.now().difference(timestamp);
    return remaining.isNegative ? 0 : remaining.inSeconds + 1;
  }

  void setCabinetShutdownBlocked(bool value) {
    _cabinetShutdownBlocked.value = value;
    update();
  }

  bool inputStatus(MainboardInput input) {
    for (final pinState in pinStates) {
      if (pinState.device == mainboardId &&
          pinState.type == PinType.digitalInput &&
          pinState.number == input.number) {
        return pinState.status;
      }
    }
    return false;
  }

  Future<void> soundTap() async {
    if (_isBuzzerPatternRunning || buzzer == null) return;
    _isBuzzerPatternRunning = true;
    try {
      buzzer!.write(true);
      _buzzerState.value = true;
      await CU.wait(100);
    } finally {
      buzzer?.write(false);
      _buzzerState.value = false;
      _isBuzzerPatternRunning = false;
      update();
    }
  }

  Future<void> soundError() async {
    if (_isBuzzerPatternRunning || buzzer == null) return;
    _isBuzzerPatternRunning = true;
    try {
      for (var index = 0; index < 3; index++) {
        buzzer!.write(true);
        _buzzerState.value = true;
        await CU.wait(1000);
        buzzer!.write(false);
        _buzzerState.value = false;
        if (index < 2) await CU.wait(1000);
      }
    } finally {
      buzzer?.write(false);
      _buzzerState.value = false;
      _isBuzzerPatternRunning = false;
      update();
    }
  }

  void setAutoMode(bool enabled) {
    _isAutoMode.value = enabled;
    _nextAutoSwitchAt = enabled
        ? DateTime.now().add(
            Duration(
              minutes: _settingsService.settings.autoSwitchIntervalMinutes,
            ),
          )
        : null;
    update();
  }

  void setDesiredTemperature(int value) {
    if (value < 16 || value > 30) return;
    _desiredTemperature.value = value;
    setAutoMode(false);
    final connectedUnits = units.values.where((unit) => unit.isConnected);
    final targetUnit =
        connectedUnits.where((unit) => unit.isRunning).firstOrNull ??
        connectedUnits
            .where((unit) => unit.lastResponseAt != null)
            .firstOrNull ??
        connectedUnits.firstOrNull;
    if (targetUnit == null) {
      update();
      return;
    }
    if (targetUnit.targetTemperature != value) {
      _messageStack.removeWhere(
        (message) =>
            message.device == targetUnit.deviceId &&
            message.command == SerialKeys.cmdSetValue,
      );
      _messageStack.insert(
        0,
        SerialMessage(
          device: targetUnit.deviceId,
          command: SerialKeys.cmdSetValue,
          arg: value & 0xFF,
        ),
      );
    }
    update();
  }

  void requestTurnOn(int deviceId, {bool isAutomatic = false}) {
    if (unitFor(deviceId).isRunning || !canTurnOn(deviceId)) return;
    if (!isAutomatic) setAutoMode(false);
    // In automatic mode we still rotate: only one unit runs at a time.
    // In manual mode the user may run both units simultaneously.
    if (isAutomatic) {
      final otherDeviceId = deviceId == SerialKeys.device1
          ? SerialKeys.device2
          : SerialKeys.device1;
      final otherUnit = unitFor(otherDeviceId);
      if (otherUnit.isRunning) {
        if (!canTurnOff(otherDeviceId)) return;
        addToSerialMessageStack(
          SerialMessage(device: otherDeviceId, command: SerialKeys.cmdTurnOff),
        );
      }
    }
    addToSerialMessageStack(
      SerialMessage(device: deviceId, command: SerialKeys.cmdTurnOn),
    );
    final targetUnit = unitFor(deviceId);
    if (targetUnit.targetTemperature != desiredTemperature) {
      addToSerialMessageStack(
        SerialMessage(
          device: deviceId,
          command: SerialKeys.cmdSetValue,
          arg: desiredTemperature & 0xFF,
        ),
      );
    }
  }

  void requestTurnOff(
    int deviceId, {
    bool force = false,
    bool isAutomatic = false,
  }) {
    if (!force && !canTurnOff(deviceId)) return;
    if (!isAutomatic) setAutoMode(false);
    addToSerialMessageStack(
      SerialMessage(device: deviceId, command: SerialKeys.cmdTurnOff),
    );
  }

  void requestStopAll({bool force = false}) {
    setAutoMode(false);
    for (final deviceId in [SerialKeys.device1, SerialKeys.device2]) {
      if (force || canTurnOff(deviceId)) {
        addToSerialMessageStack(
          SerialMessage(device: deviceId, command: SerialKeys.cmdTurnOff),
        );
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    _connectivityService = Get.find<ConnectivityService>();
    _serialService = Get.find<SerialService>();
    _telemetryRepository = TelemetryRepository(Get.find());
    _settingsService = Get.find<SettingsService>();

    _syncInitialValues();
    _setupEverListeners();

    _initializeApp();
  }

  @override
  void dispose() {
    _serialMessageSubscription?.cancel();
    _serialService.dispose();
    uartModeTx?.dispose();
    btn1?.dispose();
    btn2?.dispose();
    btn3?.dispose();
    btn4?.dispose();
    outPinSER?.dispose();
    outPinSRCLK?.dispose();
    outPinRCLK?.dispose();
    buzzer?.dispose();
    in1?.dispose();
    in2?.dispose();
    in3?.dispose();
    in4?.dispose();
    in5?.dispose();
    in6?.dispose();
    in7?.dispose();
    in8?.dispose();
    txEnablePin?.dispose();
    spiAdc?.dispose();
    super.dispose();
  }

  void _syncInitialValues() {
    _isOnline.value = _connectivityService.isConnected;
  }

  void _setupEverListeners() {
    ever(_connectivityService.isConnectedRx, (isConnected) {
      _isOnline.value = isConnected;
      update();
    });
    ever(_settingsService.settingsRx, (AppSettings settings) {
      if (isAutoMode && _nextAutoSwitchAt != null) {
        _nextAutoSwitchAt = DateTime.now().add(
          Duration(minutes: settings.autoSwitchIntervalMinutes),
        );
        update();
      }
    });
  }

  //region MARK: Connectivity
  final RxBool _isOnline = false.obs;
  bool get isOnline => _isOnline.value;
  //endregion

  //region MARK: init
  Future<void> _initializeApp() async {
    try {
      _initStatus.value = 'Cihazlar hazırlanıyor...';
      update();
      await Future.delayed(const Duration(milliseconds: 50));
      _initializeDevices();

      _initStatus.value = 'GPIO hazırlanıyor...';
      update();
      await Future.delayed(const Duration(milliseconds: 50));
      await _initializeGpio();

      _initStatus.value = 'Seri bağlantı hazırlanıyor...';
      update();
      await Future.delayed(const Duration(milliseconds: 50));
      await _initializeSerial();
    } on Object catch (error) {
      print('Başlatma hatası: $error');
      _initStatus.value = 'Donanım bağlantısı olmadan çalışıyor';
    } finally {
      _isInitializing.value = false;
      update();
    }
  }
  //endregion

  //region MARK: GPIO

  final RxBool _buzzerState = false.obs;
  bool get buzzerState => _buzzerState.value;

  final RxBool _pinUartModeTxState = false.obs;
  bool get pinUartModeTxState => _pinUartModeTxState.value;

  final RxBool _spiMisoState = false.obs;
  bool get spiMisoState => _spiMisoState.value;

  final RxBool _outOEState = false.obs;
  bool get outOEState => _outOEState.value;

  final RxBool _outSRCLKState = false.obs;
  bool get outSRCLKState => _outSRCLKState.value;

  final RxBool _outRCLKState = false.obs;
  bool get outRCLKState => _outRCLKState.value;

  final RxBool _outSERState = false.obs;
  bool get outSERState => _outSERState.value;

  Future<void> _initializeGpio() async {
    if (!Platform.isLinux) return;
    print('GPIO init: #0');
    try {
      uartModeTx = GPIO(4, GPIOdirection.gpioDirOut);
    } on GPIOexception catch (e) {
      print('GPIO init: uartModeTx ${e.toString()}');
    } catch (e) {
      print('GPIO init: ${e.toString()}');
    }
    try {
      buzzer = GPIO(0, GPIOdirection.gpioDirOut);
    } catch (e) {
      print('GPIO init: #2 ${e.toString()}');
    }
    try {
      btn1 = GPIO(17, GPIOdirection.gpioDirIn);
    } catch (e) {
      print('GPIO init: #3 ${e.toString()}');
    }
    try {
      btn2 = GPIO(18, GPIOdirection.gpioDirIn);
    } catch (e) {
      print('GPIO init: #4 ${e.toString()}');
    }
    try {
      btn3 = GPIO(27, GPIOdirection.gpioDirIn);
    } catch (e) {
      print('GPIO init: #5 ${e.toString()}');
    }
    try {
      btn4 = GPIO(22, GPIOdirection.gpioDirIn);
    } catch (e) {
      print('GPIO init: #6 ${e.toString()}');
    }
    try {
      outPinSER = GPIO(23, GPIOdirection.gpioDirOut);
    } catch (e) {
      print('GPIO init: #7 ${e.toString()}');
    }
    try {
      outPinSRCLK = GPIO(24, GPIOdirection.gpioDirOut);
    } catch (e) {
      print('GPIO init: #8 ${e.toString()}');
    }
    try {
      outPinRCLK = GPIO(25, GPIOdirection.gpioDirOut);
    } catch (e) {
      print('GPIO init: #9 ${e.toString()}');
    }
    try {
      in1 = GPIO(5, GPIOdirection.gpioDirIn);
    } catch (e) {
      print('GPIO init: #10 ${e.toString()}');
    }
    try {
      in2 = GPIO(6, GPIOdirection.gpioDirIn);
    } catch (e) {
      print('GPIO init: #11 ${e.toString()}');
    }
    try {
      in3 = GPIO(12, GPIOdirection.gpioDirIn);
    } catch (e) {
      print('GPIO init: #12 ${e.toString()}');
    }
    try {
      in4 = GPIO(13, GPIOdirection.gpioDirIn);
    } catch (e) {
      print('GPIO init: #13 ${e.toString()}');
    }
    try {
      in5 = GPIO(19, GPIOdirection.gpioDirIn);
    } catch (e) {
      print('GPIO init: #14 ${e.toString()}');
    }
    try {
      in6 = GPIO(16, GPIOdirection.gpioDirIn);
    } catch (e) {
      print('GPIO init: #15 ${e.toString()}');
    }
    try {
      in7 = GPIO(26, GPIOdirection.gpioDirIn);
    } catch (e) {
      print('GPIO init: #16 ${e.toString()}');
    }
    try {
      in8 = GPIO(20, GPIOdirection.gpioDirIn);
    } catch (e) {
      print('GPIO init: #17 ${e.toString()}');
    }
    try {
      txEnablePin = GPIO(21, GPIOdirection.gpioDirOut);
    } catch (e) {
      print('GPIO init: #18 ${e.toString()}');
    }
    try {
      spiAdc = SPI(0, 0, SPImode.mode0, 1000000);
    } catch (e) {
      print('GPIO init: #19 ${e.toString()}');
    }
    await CU.wait(50);

    // pin states
    _pinStates.clear();
    for (final deviceId in deviceIds) {
      if (deviceId == mainboardId) {
        // mainboard
        for (final i in eightInts) {
          // digital inputs
          _pinStates.add(
            PinState(
              device: mainboardId,
              number: i,
              status: false,
              type: PinType.digitalInput,
              pin: getInputPinByNumber(i),
            ),
          );
          // digital outputs
          _pinStates.add(
            PinState(
              device: mainboardId,
              number: i,
              status: false,
              type: PinType.digitalOutput,
            ),
          );
        }

        // mainboard
        for (final i in fourInts) {
          // NTC inputs
          _pinStates.add(
            PinState(device: mainboardId, number: i, type: PinType.analogInput),
          );
          // hardware buttons
          _pinStates.add(
            PinState(
              device: mainboardId,
              number: i,
              type: PinType.buttonInput,
              pin: getButtonPinByNumber(i),
            ),
          );
        }
      } else {
        // extension device
        for (final i in sixInts) {
          // inputs
          _pinStates.add(
            PinState(device: deviceId, number: i, type: PinType.digitalInput),
          );
          // outputs
          _pinStates.add(
            PinState(device: deviceId, number: i, type: PinType.digitalOutput),
          );
        }
        // adc (ntc)
        _pinStates.add(
          PinState(device: deviceId, number: one, type: PinType.analogInput),
        );
      }
    }

    update();
    await CU.wait(50);
    print('GPIO init: #20');

    await resetOutputs();
    print('GPIO init: #21');

    runGpioInputPolling();
    print('GPIO init: #22');
  }

  Future<void> resetOutputs() async {
    await CU.wait(1);
    for (int i = 1; i <= 8; i++) {
      writeSER(false);
      await CU.wait(1);
      writeSRCLK(true);
      await CU.wait(1);
      writeSRCLK(false);
      await CU.wait(1);
    }
    writeRCLK(true);
    await CU.wait(1);
    writeRCLK(false);
    await CU.wait(1);
    writeOE(false);
  }

  void writeOE(bool value) {
    try {
      final actualValue = _invertUartTx.value ? value : !value;
      txEnablePin?.write(actualValue);
      _outOEState.value = actualValue;
      update();
    } on Exception catch (_) {
      //
    }
  }

  void writeSRCLK(bool value) {
    try {
      outPinSRCLK?.write(value);
      _outSRCLKState.value = value;
      update();
    } on Exception catch (_) {
      //
    }
  }

  void writeRCLK(bool value) {
    try {
      outPinRCLK?.write(value);
      _outRCLKState.value = value;
      update();
    } on Exception catch (_) {
      //
    }
  }

  void writeSER(bool value) {
    try {
      outPinSER?.write(value);
      _outSERState.value = value;
      update();
    } on Exception catch (_) {
      //
    }
  }

  void runGpioInputPolling() {
    _inputPollIndicator.toggle();
    try {
      for (PinState item in pinStates.where((e) => e.pin != null)) {
        final bool newStatus = !item.pin!.read();
        if (item.status != newStatus) {
          item.status = newStatus;
          updatePinState(item);
          if (item.type == PinType.digitalInput) {
            _inputRevision.value++;
          } else if (item.type == PinType.buttonInput && newStatus) {
            unawaited(_navigateForButton(item.number));
          }
          final String typeLabel = item.type == PinType.buttonInput
              ? 'Button'
              : 'Input';
          print('$typeLabel ${item.number}: ${newStatus ? "HIGH" : "LOW"}');
        }
      }
      pollNtcSensors();
    } on Exception catch (e) {
      print('ERROR polling: $e');
    }
    update();
    Future.delayed(Duration(milliseconds: 100), () => runGpioInputPolling());
  }

  Future<void> _navigateForButton(int number) async {
    await soundTap();
    switch (number) {
      case 1:
        _showShutdownDialog();
        return;
      case 2:
        setAutoMode(true);
        break;
      case 3:
        requestManualToggle(SerialKeys.device1);
        break;
      case 4:
        requestManualToggle(SerialKeys.device2);
        break;
      default:
        return;
    }
    if (Get.currentRoute != Routes.dashboard) {
      Get.offAllNamed(Routes.dashboard);
    }
  }

  /// Disables auto mode and toggles the requested AC unit on or off,
  /// respecting the cooldown checks in [canTurnOn] and [canTurnOff].
  void requestManualToggle(int deviceId) {
    setAutoMode(false);
    if (unitFor(deviceId).isRunning) {
      requestTurnOff(deviceId);
    } else {
      requestTurnOn(deviceId);
    }
  }

  void _showShutdownDialog() {
    if (Get.isDialogOpen ?? false) return;
    Get.dialog(
      AlertDialog(
        title: const Text('Sistemi kapatmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              Get.back();
              unawaited(shutdownPi());
            },
            child: const Text('Sistemi Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> shutdownPi() async {
    try {
      await Process.run('sudo', ['shutdown', '-h', 'now']);
    } on Exception catch (e) {
      print('ERROR shutting down: $e');
    }
  }

  void pollNtcSensors() {
    if (spiAdc == null) return;

    for (int channel = 4; channel <= 7; channel++) {
      final int rawValue = readMcp3008Channel(channel);
      final int ntcNumber = channel - 3; // channels 4-7 -> NTC 1-4
      final double celsius = calculateNtcCelsius(rawValue);

      final ntcStates = getPinStates(
        device: mainboardId,
        number: ntcNumber,
        type: PinType.analogInput,
      );
      if (ntcStates.isNotEmpty) {
        final ps = ntcStates.first;
        ps.value = celsius;
        updatePinState(ps);
      }
    }
  }

  int readMcp3008Channel(int channel) {
    if (spiAdc == null || channel < 0 || channel > 7) return 0;

    try {
      // MCP3008 protocol: send 3 bytes, receive 3 bytes
      // Byte 0: Start bit (0x01)
      // Byte 1: Single-ended mode (0x80) + channel (shifted left 4)
      // Byte 2: Don't care (0x00)
      final txData = [0x01, (0x80 | (channel << 4)), 0x00];
      final rxData = spiAdc!.transfer(txData, false);

      // Result is in last 10 bits of bytes 1 and 2
      final int result = ((rxData[1] & 0x03) << 8) | rxData[2];
      return result;
    } on Exception catch (_) {
      return 0;
    }
  }

  double calculateNtcCelsius(int rawValue) {
    if (rawValue <= 0 || rawValue >= 1023) return -999.0;

    const double vcc = 5.0;
    const int rs = 10000;
    const double res = 0.0048828125; // 5V / 1024
    const double a = 0.001129148;
    const double b = 0.000234125;
    const double c = 0.0000000876741;

    final double adcValue = rawValue.toDouble();
    final double vNtc = adcValue * res;
    final double rNtc = (rs * vNtc) / (vcc - vNtc);
    double tNtc = math.log(rNtc);
    tNtc = 1 / (a + (b * tNtc) + (c * tNtc * tNtc * tNtc));
    tNtc = tNtc - 273.15;

    return tNtc;
  }

  //endregion

  //region MARK: PinStates
  final RxList<PinState> _pinStates = <PinState>[].obs;
  List<PinState> get pinStates => _pinStates;
  List<PinState> getPinStates({int? device, int? number, PinType? type}) =>
      pinStates
          .where(
            (e) =>
                (device == null || e.device == device) &&
                (number == null || e.number == number) &&
                (type == null || e.type == type),
          )
          .toList();

  void updatePinState(PinState ps) {
    int index = pinStates.indexWhere(
      (p) =>
          p.device == ps.device && p.number == ps.number && p.type == ps.type,
    );
    if (index != -1) {
      _pinStates[index].status = ps.status;
      _pinStates[index].value = ps.value;
      update();
    }
  }

  bool getPinState({
    required int device,
    required int number,
    required PinType type,
  }) {
    return pinStates
        .firstWhere(
          (e) => e.device == device && e.number == number && e.type == type,
        )
        .status;
  }

  double? getPinValue({
    required int device,
    required int number,
    required PinType type,
  }) {
    return pinStates
        .firstWhere(
          (e) => e.device == device && e.number == number && e.type == type,
        )
        .value;
  }

  GPIO? getInputPinByNumber(int a) {
    switch (a) {
      case 0x01:
        return in1;
      case 0x02:
        return in2;
      case 0x03:
        return in3;
      case 0x04:
        return in4;
      case 0x05:
        return in5;
      case 0x06:
        return in6;
      case 0x07:
        return in7;
      case 0x08:
        return in8;
    }
    return null;
  }

  GPIO? getButtonPinByNumber(int a) {
    switch (a) {
      case 0x01:
        return btn1;
      case 0x02:
        return btn2;
      case 0x03:
        return btn3;
      case 0x04:
        return btn4;
    }
    return null;
  }
  //endregion

  //region MARK: Devices
  final RxList<int> _deviceIds = <int>[].obs;
  List<int> get deviceIds => _deviceIds;
  void _initializeDevices() {
    _deviceIds.assignAll([mainboardId, SerialKeys.device1, SerialKeys.device2]);
    update();
  }
  //endregion

  //region MARK: Serial
  final RxBool _allowSerialLoop = false.obs;
  bool get allowSerialLoop => _allowSerialLoop.value;

  final RxBool _processingSerialLoop = false.obs;
  bool get processingSerialLoop => _processingSerialLoop.value;

  final RxList<SerialMessage> _messageStack = <SerialMessage>[].obs;
  List<SerialMessage> get messageStack => _messageStack;

  final Rxn<SerialMessage> _currentSerialMessage = Rxn<SerialMessage>();
  SerialMessage? get currentSerialMessage => _currentSerialMessage.value;

  final RxList<List<int>> _sentData = <List<int>>[].obs;
  List<List<int>> get sentData => _sentData;

  final RxList<List<int>> _receivedData = <List<int>>[].obs;
  List<List<int>> get receivedData => _receivedData;

  Future<void> _initializeSerial() async {
    if (!Platform.isLinux) return;

    final success = await _serialService.initialize();

    if (!success) return;

    // subscribe
    _serialMessageSubscription?.cancel();
    _serialMessageSubscription = _serialService.onMessage.listen((
      Uint8List data,
    ) {
      _onSerialMessageReceived(data);
    });

    // Wake-up handshake: give the extension board one comm-test exchange
    // before the first Read All, so it is ready to emit the full 15-byte response.
    print('Serial handshake...');
    await sendSerialMessage(
      SerialMessage(
        device: SerialKeys.device1,
        command: SerialKeys.cmdCommTest,
      ),
    );
    await waitForSerialResponse();
    print('Serial handshake complete');

    // run polling
    _allowSerialLoop.value = true;
    update();

    runSerialLoop();
  }

  void _onSerialMessageReceived(Uint8List data) {
    List<int> rawData = data.toList();
    _markDeviceConnected(rawData[1]);

    // Validate CRC
    // if (!SerialUtils.validateCrc(rawData)) {
    //   print('ERROR: Invalid CRC received');
    //   return;
    // }
    // skip crc check

    _receivedData.add(rawData);
    if (_receivedData.length > 50) _receivedData.removeAt(0);
    update();

    _parseSerialMessage(rawData);
  }

  void _parseSerialMessage(List<int> data) {
    final deviceId = data[1];
    final commandByte = data[2];
    final sentMessage = currentSerialMessage;
    final sentCommand = sentMessage?.command ?? -1;

    // Clear current message if this is the response.
    // Read-value replies replace the command byte with the value itself,
    // so for read commands (0xCA+) we also accept a 7-byte reply from the
    // same device.
    if (sentMessage != null &&
        sentMessage.device == deviceId &&
        (sentMessage.command == commandByte ||
            (sentMessage.command >= SerialKeys.cmdReadValue &&
                data.length == kNormalMessageLength))) {
      _currentSerialMessage.value = null;
      update();
    }

    switch (sentCommand) {
      case SerialKeys.cmdReadAll:
        _updateUnitFromReadAll(deviceId, data);
      default:
        break;
    }
  }

  void _updateUnitFromReadAll(int deviceId, List<int> data) {
    if (data.length != kReadAllMessageLength) return;
    final values = data.sublist(3, data.length - 2);
    if (values.length < 10) return;

    final previous = unitFor(deviceId);
    final now = DateTime.now();
    final isRunning = values[1] != 0;
    final hasError = values[0] != 0;
    final updated = previous.copyWith(
      errorCode: values[0],
      status: values[1],
      targetTemperature: values[2].toSigned(8),
      ntc0: values[3].toSigned(8),
      ntc1: values[4].toSigned(8),
      ntc2: values[5].toSigned(8),
      ntc3: values[6].toSigned(8),
      fanLevel: values[9].toSigned(8),
      isRunning: isRunning,
      lastResponseAt: now,
      lastTurnedOnAt: !previous.isRunning && isRunning
          ? now
          : previous.lastTurnedOnAt,
      lastTurnedOffAt: previous.isRunning && !isRunning
          ? now
          : previous.lastTurnedOffAt,
      failureStartedAt: hasError ? previous.failureStartedAt ?? now : null,
      clearFailureStartedAt: !hasError,
      isConnected: true,
      clearNextProbeAt: true,
      clearCommunicationFailureStartedAt: true,
    );
    _units[deviceId] = updated;
    _recordTemperatureSample(previous, updated, now);
    if (_isTemperatureControlUnit(deviceId) &&
        !_hasPendingSetValueCommand(deviceId)) {
      _desiredTemperature.value = updated.targetTemperature!;
    }
    _evaluateAutomation(updated);

    if (previous.isRunning != isRunning) {
      unawaited(
        _telemetryRepository.recordRuntimeEvent(
          deviceId: deviceId,
          eventType: isRunning ? 'turned_on' : 'turned_off',
          reason: 'device_status',
          occurredAt: now,
        ),
      );
    }
    if (previous.errorCode != values[0]) {
      unawaited(
        _telemetryRepository.recordChange(
          sourceType: 'unit',
          sourceId: deviceId.toString(),
          metric: 'error_code',
          previousValue: previous.errorCode.toString(),
          newValue: values[0].toString(),
          occurredAt: now,
        ),
      );
    }
    update();
  }

  void _recordTemperatureSample(
    AcUnitState previous,
    AcUnitState updated,
    DateTime now,
  ) {
    if (!updated.isRunning ||
        updated.ntc1 == null ||
        updated.targetTemperature == null) {
      return;
    }
    final lastSampleAt = _lastTemperatureSampleAt[updated.deviceId];
    final targetChanged =
        previous.targetTemperature != updated.targetTemperature;
    if (!targetChanged &&
        lastSampleAt != null &&
        now.difference(lastSampleAt) < temperatureSampleInterval) {
      return;
    }
    _lastTemperatureSampleAt[updated.deviceId] = now;
    unawaited(
      _telemetryRepository.recordTemperatureSample(
        deviceId: updated.deviceId,
        temperature: updated.ntc1!,
        targetTemperature: updated.targetTemperature!,
        occurredAt: now,
      ),
    );
  }

  bool _isTemperatureControlUnit(int deviceId) {
    final connectedUnits = units.values.where(
      (unit) => unit.isConnected && unit.targetTemperature != null,
    );
    final unit =
        connectedUnits.where((unit) => unit.isRunning).firstOrNull ??
        connectedUnits.where((unit) => unit.lastResponseAt != null).firstOrNull;
    return unit?.deviceId == deviceId;
  }

  bool _hasPendingSetValueCommand(int deviceId) {
    final current = currentSerialMessage;
    return (current?.device == deviceId &&
            current?.command == SerialKeys.cmdSetValue) ||
        messageStack.any(
          (message) =>
              message.device == deviceId &&
              message.command == SerialKeys.cmdSetValue,
        );
  }

  void _evaluateAutomation(AcUnitState unit) {
    final now = DateTime.now();
    final failureStartedAt = unit.hasError ? unit.failureStartedAt : null;
    final backupDeviceId = unit.deviceId == SerialKeys.device1
        ? SerialKeys.device2
        : SerialKeys.device1;
    if (failureStartedAt != null &&
        now.difference(failureStartedAt) >= const Duration(seconds: 15) &&
        !_handledFailureDevices.contains(unit.deviceId) &&
        canTurnOff(unit.deviceId) &&
        canTurnOn(backupDeviceId)) {
      _handledFailureDevices.add(unit.deviceId);
      requestTurnOff(unit.deviceId, isAutomatic: true);
      requestTurnOn(backupDeviceId, isAutomatic: true);
    }
    if (!unit.hasError) {
      _handledFailureDevices.remove(unit.deviceId);
    }

    if (!isAutoMode ||
        _nextAutoSwitchAt == null ||
        now.isBefore(_nextAutoSwitchAt!)) {
      return;
    }
    final runningUnit = units.values
        .where((item) => item.isRunning)
        .firstOrNull;
    if (runningUnit == null) return;
    final rotationDeviceId = runningUnit.deviceId == SerialKeys.device1
        ? SerialKeys.device2
        : SerialKeys.device1;
    requestTurnOn(rotationDeviceId, isAutomatic: true);
    _nextAutoSwitchAt = now.add(
      Duration(minutes: _settingsService.settings.autoSwitchIntervalMinutes),
    );
    update();
  }

  void _setTxEnable(bool value) {
    final gpioValue = invertUartTx ? !value : value;
    uartModeTx?.write(gpioValue);
    _pinUartModeTxState.value = value;
  }

  void addToSerialMessageStack(SerialMessage m) {
    _messageStack.add(m);
    update();
  }

  Future<void> sendSerialMessage(SerialMessage m) async {
    final bytes = m.toBytesWithCrc();

    _currentSerialMessage.value = m;
    update();

    await _serialService.sendMessage(m, setTxEnable: _setTxEnable);

    _sentData.add(bytes);
    if (_sentData.length > 50) _sentData.removeAt(0);
    update();
  }

  Future<void> sendSerialMessageFromStack() async {
    if (_messageStack.isNotEmpty) {
      SerialMessage m = _messageStack.removeAt(0);
      await sendSerialMessage(m);
    }
  }

  void turnOnSerialLoop() {
    _allowSerialLoop.value = true;
    update();
    runSerialLoop();
  }

  void turnOffSerialLoop() {
    _allowSerialLoop.value = false;
    _processingSerialLoop.value = false;
    update();
  }

  Future<void> runSerialLoop() async {
    if (!allowSerialLoop) return;

    _processingSerialLoop.value = true;
    update();

    // 1. Send any queued commands first.
    while (messageStack.isNotEmpty) {
      await sendSerialMessageFromStack();
      await waitForSerialResponse();
    }

    // 2. Query each extension device sequentially.
    for (final deviceId in deviceIds.where((e) => e != mainboardId)) {
      if (!_shouldPollDevice(deviceId)) continue;
      final isRecoveryProbe = !unitFor(deviceId).isConnected;
      final command = isRecoveryProbe
          ? SerialKeys.cmdCommTest
          : SerialKeys.cmdReadAll;
      await sendSerialMessage(
        SerialMessage(device: deviceId, command: command),
      );
      await waitForSerialResponse();
    }

    _processingSerialLoop.value = false;
    update();

    await CU.wait(kSerialLoopDelay);
    if (allowSerialLoop) {
      runSerialLoop();
    }
  }

  Future<void> waitForSerialResponse() async {
    if (currentSerialMessage == null) {
      return;
    }

    if (currentSerialMessage!.command == SerialKeys.cmdReset) {
      // Restart command - device cannot respond while restarting
      await CU.wait(kSerialAcknowledgementDelay);
      _currentSerialMessage.value = null;
      update();
      return;
    }

    int timeoutMillis = 0;
    const pollStepMillis = 10;

    while (currentSerialMessage != null &&
        timeoutMillis < kSerialResponseTimeoutMillis) {
      timeoutMillis += pollStepMillis;
      await CU.wait(pollStepMillis);
      if (timeoutMillis >= kSerialResponseTimeoutMillis) {
        _markCommunicationTimeout(currentSerialMessage!.device);
        _currentSerialMessage.value = null;
        update();
        return;
      }
    }
  }

  bool _shouldPollDevice(int deviceId) {
    final unit = unitFor(deviceId);
    if (unit.isConnected) return true;

    final skipRemaining = _skipPollCounts[deviceId] ?? 0;
    if (skipRemaining > 0) {
      _skipPollCounts[deviceId] = skipRemaining - 1;
      return false;
    }
    return true;
  }

  void _markDeviceConnected(int deviceId) {
    if (deviceId == mainboardId) return;
    _communicationTimeoutCounts.remove(deviceId);
    _skipPollCounts.remove(deviceId);
    final previous = unitFor(deviceId);
    if (previous.isConnected && previous.nextProbeAt == null) return;
    _units[deviceId] = previous.copyWith(
      isConnected: true,
      clearNextProbeAt: true,
      clearCommunicationFailureStartedAt: true,
    );
    update();
  }

  void _markCommunicationTimeout(int deviceId) {
    final now = DateTime.now();
    var count = (_communicationTimeoutCounts[deviceId] ?? 0) + 1;
    final previous = unitFor(deviceId);
    final isDisconnected = count >= maxConsecutiveCommunicationTimeouts;
    if (isDisconnected) {
      _skipPollCounts[deviceId] = 100;
      count = 0;
    }
    _communicationTimeoutCounts[deviceId] = count;
    final updated = previous.copyWith(
      isConnected: !isDisconnected,
      clearNextProbeAt: true,
      communicationFailureStartedAt:
          previous.communicationFailureStartedAt ?? now,
    );
    _units[deviceId] = updated;
    if (isDisconnected) {
      _messageStack.removeWhere((message) => message.device == deviceId);
    }
    final startedAt = updated.communicationFailureStartedAt!;
    final backupDeviceId = deviceId == SerialKeys.device1
        ? SerialKeys.device2
        : SerialKeys.device1;
    if (now.difference(startedAt) >= const Duration(seconds: 15) &&
        !_handledFailureDevices.contains(deviceId) &&
        canTurnOff(deviceId) &&
        canTurnOn(backupDeviceId)) {
      _handledFailureDevices.add(deviceId);
      requestTurnOff(deviceId, isAutomatic: true);
      requestTurnOn(backupDeviceId, isAutomatic: true);
    }
    update();
  }

  //endregion

  //region MARK: UI State
  final RxBool _isInitializing = true.obs;
  bool get isInitializing => _isInitializing.value;

  final RxString _initStatus = 'Starting...'.obs;
  String get initStatus => _initStatus.value;

  final RxInt _selectedDeviceId = mainboardId.obs;
  int get selectedDeviceId => _selectedDeviceId.value;

  final RxBool _inputPollIndicator = false.obs;
  bool get inputPollIndicator => _inputPollIndicator.value;

  final RxBool _invertUartTx = true.obs;
  bool get invertUartTx => _invertUartTx.value;
  void toggleInvertUartTx() {
    _invertUartTx.value = !_invertUartTx.value;
    print('UART TX Invert: ${_invertUartTx.value}');
    update();
  }

  //endregion
}
