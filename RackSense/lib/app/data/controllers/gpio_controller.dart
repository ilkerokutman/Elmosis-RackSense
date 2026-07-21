// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dart_periphery/dart_periphery.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/core/utils/common_utils.dart';
import 'package:rack_sense/app/data/models/pin_state.dart';
import 'package:rack_sense/app/data/services/serial_service.dart';

class GpioController extends GetxController {
  late final SerialService _serialService;
  StreamSubscription<Uint8List>? _serialMessageSubscription;
  //
  @override
  void onInit() {
    super.onInit();
    _serialService = Get.find<SerialService>();
  }

  final List<bool> _outputStates = List.filled(8, false);
  List<bool> get outputStates => List.unmodifiable(_outputStates);

  GPIO? _serPin;
  GPIO? _srclkPin;
  GPIO? _rclkPin;
  GPIO? _txEnablePin;
  GPIO? _buzzerPin;
  GPIO? _fanPin;
  SPI? _spiAdc;
  GPIO? uartModeTx;

  final Map<int, GPIO> _inputPins = {};
  final Map<int, GPIO> _buttonPins = {};

  static const int serPin = 23;
  static const int srclkPin = 24;

  static const int rclkPin = 25;
  static const int txEnablePin = 21;
  static const int buzzerPin = 0;
  static const int fanPin = 7;

  static const List<int> inputPins = [5, 6, 12, 13, 19, 16, 26, 20];
  static const List<int> buttonPins = [17, 18, 27, 22];

  final RxBool _initCompleted = false.obs;
  bool get initCompleted => _initCompleted.value;
  int get inputPinCount => _inputPins.length;
  int get buttonPinCount => _buttonPins.length;
  bool get spiInitialized => _spiAdc != null;

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

  final RxBool _buzzerState = false.obs;
  bool get buzzerState => _buzzerState.value;

  Future<void> initialize() async {
    if (!Platform.isLinux) {
      return;
    }

    print('GPIO: Starting init');

    try {
      uartModeTx = GPIO(txEnablePin, GPIOdirection.gpioDirOut);
    } catch (e) {
      print('txpin error: ${e.toString()}');
    }

    try {
      _serPin = GPIO(serPin, GPIOdirection.gpioDirOut);

      _srclkPin = GPIO(srclkPin, GPIOdirection.gpioDirOut);

      _rclkPin = GPIO(rclkPin, GPIOdirection.gpioDirOut);

      _txEnablePin = GPIO(txEnablePin, GPIOdirection.gpioDirOut);

      _buzzerPin = GPIO(buzzerPin, GPIOdirection.gpioDirOut);

      // _fanPin = GPIO(fanPin, GPIOdirection.gpioDirOut);

      for (final int pin in inputPins) {
        final gpio = GPIO(pin, GPIOdirection.gpioDirIn);
        _inputPins[pin] = gpio;
      }

      for (final int pin in buttonPins) {
        final gpio = GPIO(pin, GPIOdirection.gpioDirIn);
        _buttonPins[pin] = gpio;
      }

      _spiAdc = SPI(0, 0, SPImode.mode0, 1000000);

      _initCompleted.value = true;

      _serialMessageSubscription?.cancel();
      _serialMessageSubscription = _serialService.onMessage.listen((
        Uint8List data,
      ) {
        _onSerialMessageReceived(data);
      });

      update();
      print(
        'GPIO: Initialization complete. Inputs: ${_inputPins.length}, Buttons: ${_buttonPins.length}, SPI: ${_spiAdc != null}',
      );
    } on Exception catch (e) {
      print('GPIO init error: ${e.toString()}');
    }
  }

  void turnOnSerialLoop() {
    _allowSerialLoop.value = true;
    update();
    print('Serial loop enabled');
    runSerialLoop();
  }

  void turnOffSerialLoop() {
    _allowSerialLoop.value = false;
    _processingSerialLoop.value = false;
    update();
    print('Serial loop disabled');
  }

  void _writePin(GPIO? pin, bool value) {
    if (pin == null) return;
    try {
      pin.write(value);
    } catch (_) {}
  }

  Future<void> setOutput(int index, bool value) async {
    if (index < 0 || index >= 8) return;
    _outputStates[index] = value;
    await _sendOutputPackage();
  }

  Future<void> setOutputs(List<int> indices, List<bool> values) async {
    for (int i = 0; i < indices.length && i < values.length; i++) {
      final index = indices[i];
      if (index >= 0 && index < 8) {
        _outputStates[index] = values[i];
      }
    }
    await _sendOutputPackage();
  }

  Future<void> setAllOutputs(List<bool> states) async {
    for (int i = 0; i < 8 && i < states.length; i++) {
      _outputStates[i] = states[i];
    }
    await _sendOutputPackage();
  }

  Future<void> _sendOutputPackage() async {
    if (!Platform.isLinux) return;
    for (int i = 0; i < 8; i++) {
      _writePin(_serPin, _outputStates[i]);
      CU.microWait();

      _writePin(_srclkPin, true);
      CU.microWait();

      _writePin(_srclkPin, false);
      CU.microWait();
    }

    _writePin(_rclkPin, true);
    CU.microWait();

    _writePin(_rclkPin, false);
    CU.microWait();

    _writePin(_txEnablePin, false);
  }

  Future<List<bool>> readInputs() async {
    if (!_initCompleted.value) {
      print('GPIO: readInputs called but not initialized');
      return List.filled(8, false);
    }

    if (_inputPins.isEmpty) {
      print('GPIO: readInputs - _inputPins map is empty!');
      return List.filled(8, false);
    }

    final List<bool> states = [];
    for (final int pin in inputPins) {
      final gpio = _inputPins[pin];
      if (gpio == null) {
        states.add(false);
        continue;
      }
      try {
        final bool value = gpio.read();
        states.add(!value); // Invert: pull-up means LOW=active
      } catch (e) {
        print('GPIO: Error reading pin $pin: $e');
        states.add(false);
      }
    }
    return states;
  }

  bool readInput(int index) {
    if (index < 0 || index >= inputPinCount) return false;
    final gpio = _inputPins[inputPins[index]];
    if (gpio == null) return false;
    try {
      return !gpio.read();
    } catch (_) {
      return false;
    }
  }

  Future<void> buzzerBeep({int durationMs = 100}) async {
    if (!Platform.isLinux) return;
    _writePin(_buzzerPin, true);
    await Future.delayed(Duration(milliseconds: durationMs));
    _writePin(_buzzerPin, false);
  }

  Future<void> setFan(bool on) async {
    _writePin(_fanPin, on);
  }

  Future<void> emergencyShutdownAllOutputs() async {
    for (int i = 0; i < 8; i++) {
      _outputStates[i] = false;
    }
    await _sendOutputPackage();
  }

  Future<List<bool>> readButtons() async {
    if (!_initCompleted.value || _buttonPins.isEmpty) {
      return List.filled(4, false);
    }

    final List<bool> states = [];
    for (final int pin in buttonPins) {
      final gpio = _buttonPins[pin];
      if (gpio == null) {
        states.add(false);
        continue;
      }
      try {
        final bool value = gpio.read();
        states.add(!value); // Invert: LOW=pressed
      } catch (_) {
        states.add(false);
      }
    }
    return states;
  }

  int readMcp3008Channel(int channel) {
    if (_spiAdc == null || channel < 0 || channel > 7) return 0;

    try {
      final txData = [0x01, (0x80 | (channel << 4)), 0x00];
      final rxData = _spiAdc!.transfer(txData, false);
      final int result = ((rxData[1] & 0x03) << 8) | rxData[2];
      return result;
    } catch (_) {
      return 0;
    }
  }

  double readNtcCelsius(int ntcIndex) {
    if (!_initCompleted.value || _spiAdc == null) return -999.0;
    if (ntcIndex < 1 || ntcIndex > 4) return -999.0;
    final channel = ntcIndex + 3; // NTC 1-4 -> channels 4-7
    final rawValue = readMcp3008Channel(channel);
    return calculateNtcCelsius(rawValue);
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
    if (rNtc <= 0) return -999.0;

    double tNtc = _ln(rNtc);
    tNtc = 1 / (a + (b * tNtc) + (c * tNtc * tNtc * tNtc));
    tNtc = tNtc - 273.15;

    return tNtc;
  }

  double _ln(double x) {
    if (x <= 0) return 0;
    return math.log(x);
  }

  // MARK: PinStates

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

  // MARK: Serial

  final RxBool _allowSerialLoop = false.obs;
  RxBool get allowSerialLoopRx => _allowSerialLoop;
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

  void _setTxEnable(bool value) {
    uartModeTx?.write(value);
    _pinUartModeTxState.value = value;
  }

  void _onSerialMessageReceived(Uint8List data) {
    List<int> rawData = data.toList();

    // skip CRC check

    _receivedData.add(rawData);
    if (_receivedData.length > 50) _receivedData.removeAt(0);
    update();

    _parseSerialMessage(rawData);
  }

  void _parseSerialMessage(List<int> data) {
    final deviceId = data[1];
    final command = data[2];
    final index = data[3];
    final args = data[4];

    print(
      '<<<< D:0x${deviceId.toRadixString(16).padLeft(2, '0')} '
      'C:0x${command.toRadixString(16).padLeft(2, '0')} '
      'I:0x${index.toRadixString(16).padLeft(2, '0')} '
      'A:0x${args.toRadixString(16).padLeft(2, '0')}',
    );

    // clear current message if this is the response
    if (currentSerialMessage != null &&
        currentSerialMessage!.command == command &&
        currentSerialMessage!.device == deviceId) {
      _currentSerialMessage.value = null;
      update();
    }

    switch (command) {
      case 0x64: // test signal
        print('Test signal OK');
        break;
      case 0x65: // restart device
        print('device restart');
        break;
      case 0x66: // modify set value
        print('modify set value');
        break;
      case 0x67: // turn device on
        print('turn device on');
        break;
      case 0x68: // turn device off
        print('turn device off');
        break;
      case 0xCA: // read set value
        print('set degeri oku');
        break;
      case 0xCB: // NTC0 read
        print('ntc0 oku');
        break;
      case 0xCC: // NTC1 read
        print('ntc1 oku');
        break;
      case 0xCD: // NTC2 read
        print('ntc2 oku');
        break;
      case 0xCE: // NTC3 read
        print('ntc3 oku');
        break;
      case 0xCF: // read outputs
        print('read outputs');
        break;
      case 0xD0: // read inputs
        print('read inputs');
        final states = SerialUtils.parseStates(args);
        for (int i = 0; i < 6; i++) {
          final pinState = getPinStates(
            device: deviceId,
            number: i + 1,
            type: PinType.digitalInput,
          ).firstOrNull;
          if (pinState != null) {
            pinState.status = states[i];
            updatePinState(pinState);
          }
        }
        break;
      case 0xD1: // read fan level
        print('read fan level');
        break;
      case 0xD2: // read all values
        print('read all values');
        break;
    }
  }

  void addToSerialMessageStack(SerialMessage m) {
    _messageStack.add(m);
    update();
  }

  Future<void> sendSerialMessage(SerialMessage m) async {
    final bytes = m.toBytesWithCrc();
    final hexStr = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
    print('>>>>> $hexStr');

    _currentSerialMessage.value = m;
    update();

    await _serialService.sendMessage(m, setTxEnable: _setTxEnable);

    _sentData.add(bytes);
    if (_sentData.length > 50) _sentData.removeAt(0);
    update();
  }

  Future<void> sendSerialMessageFromStack() async {
    if (_messageStack.isNotEmpty) {
      print('taking message from stack (${_messageStack.length}) remaining');
      SerialMessage m = _messageStack.removeAt(0);
      await sendSerialMessage(m);
    }
  }

  Future<void> runSerialLoop() async {
    if (!allowSerialLoop) return;

    _processingSerialLoop.value = true;
    update();

    // poll
    for (final deviceId in [0x01, 0x02]) {
      // read
      await sendSerialMessage(SerialMessage(device: deviceId, command: 0xD2));
      await waitForSerialResponse();
    }

    while (messageStack.isNotEmpty) {
      await sendSerialMessageFromStack();
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

    if (currentSerialMessage!.command == 0x65) {
      // ignore restart commands response
      await CU.wait(kSerialAcknowledgementDelay);
      _currentSerialMessage.value = null;
      update();
      return;
    }

    int timeoutMillis = 0;
    const maxTimeout = 1000;

    while (currentSerialMessage != null &&
        timeoutMillis < kSerialAcknowledgementDelay) {
      timeoutMillis++;
      await CU.wait(1);
      if (timeoutMillis >= maxTimeout) {
        print('Error: serial response timeout');
        _currentSerialMessage.value = null;
        update();
        return;
      }
    }
  }

  @override
  void dispose() {
    _serPin?.dispose();
    _srclkPin?.dispose();
    _rclkPin?.dispose();
    _txEnablePin?.dispose();
    _buzzerPin?.dispose();
    _fanPin?.dispose();
    _spiAdc?.dispose();
    for (final gpio in _inputPins.values) {
      gpio.dispose();
    }
    for (final gpio in _buttonPins.values) {
      gpio.dispose();
    }
    _serialMessageSubscription?.cancel();
    super.dispose();
  }
}
