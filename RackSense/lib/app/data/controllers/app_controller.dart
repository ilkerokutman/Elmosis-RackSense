import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dart_periphery/dart_periphery.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/core/utils/common_utils.dart';
import 'package:rack_sense/app/data/models/pin_state.dart';
import 'package:rack_sense/app/data/services/connectivity_service.dart';
import 'package:rack_sense/app/data/services/serial_service.dart';

const List<int> eightInts = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08];
const List<int> sixInts = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06];
const List<int> fourInts = [0x01, 0x02, 0x03, 0x04];
const int mainboardId = 0x00;
const int one = 0x01;

class AppController extends GetxController {
  late final ConnectivityService _connectivityService;
  late final SerialService _serialService;
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

  late StreamSubscription<Uint8List>? _serialMessageSubscription;

  @override
  void onInit() {
    super.onInit();
    _connectivityService = Get.find<ConnectivityService>();
    _serialService = Get.find<SerialService>();

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
  }

  //region MARK: Connectivity
  final RxBool _isOnline = false.obs;
  bool get isOnline => _isOnline.value;
  //endregion

  //region MARK: init
  Future<void> _initializeApp() async {
    _initStatus.value = 'Loading devices...';
    update();
    await Future.delayed(const Duration(milliseconds: 50));
    _initializeDevices();

    _initStatus.value = 'Initializing GPIO...';
    update();
    await Future.delayed(const Duration(milliseconds: 50));
    await _initializeGpio();

    _initStatus.value = 'Initializing Serial...';
    update();
    await Future.delayed(const Duration(milliseconds: 50));
    await _initializeSerial();

    _isInitializing.value = false;
    print('Initialization complete');
    update();
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

    try {
      uartModeTx = GPIO(4, GPIOdirection.gpioDirOut);
      buzzer = GPIO(0, GPIOdirection.gpioDirOut);
      btn1 = GPIO(17, GPIOdirection.gpioDirIn);
      btn2 = GPIO(18, GPIOdirection.gpioDirIn);
      btn3 = GPIO(27, GPIOdirection.gpioDirIn);
      btn4 = GPIO(22, GPIOdirection.gpioDirIn);
      outPinSER = GPIO(23, GPIOdirection.gpioDirOut);
      outPinRCLK = GPIO(25, GPIOdirection.gpioDirOut);
      in1 = GPIO(5, GPIOdirection.gpioDirIn);
      in2 = GPIO(6, GPIOdirection.gpioDirIn);
      in3 = GPIO(12, GPIOdirection.gpioDirIn);
      in4 = GPIO(13, GPIOdirection.gpioDirIn);
      in5 = GPIO(19, GPIOdirection.gpioDirIn);
      in6 = GPIO(16, GPIOdirection.gpioDirIn);
      in7 = GPIO(26, GPIOdirection.gpioDirIn);
      in8 = GPIO(20, GPIOdirection.gpioDirIn);
      txEnablePin = GPIO(21, GPIOdirection.gpioDirOut);
      spiAdc = SPI(0, 0, SPImode.mode0, 1000000);
    } on Exception catch (e) {
      print('initializeGpio error: ${e.toString()}');
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

    await resetOutputs();

    runGpioInputPolling();
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
    _deviceIds.assignAll([mainboardId, 0x01, 0x02]);
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

    // run polling
    _allowSerialLoop.value = true;
    update();

    runSerialLoop();
  }

  void _onSerialMessageReceived(Uint8List data) {
    List<int> rawData = data.toList();

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
    final command = data[2];
    final index = data[3];
    final args = data[4];

    print(
      '<<<< D:0x${deviceId.toRadixString(16).padLeft(2, '0')} '
      'C:0x${command.toRadixString(16).padLeft(2, '0')} '
      'I:0x${index.toRadixString(16).padLeft(2, '0')} '
      'A:0x${args.toRadixString(16).padLeft(2, '0')}',
    );

    // Clear current message if this is the response
    if (currentSerialMessage != null &&
        currentSerialMessage!.command == command &&
        currentSerialMessage!.device == deviceId) {
      _currentSerialMessage.value = null;
      update();
    }

    switch (command) {
      case 0x64: // test
      case 0x65: // device reset/reboot
      case 0x66: // update set value
      case 0x67: // turn device on
      case 0x68: // turn device off
      case 0xCA: // read set value
      case 0xCB: // read NTC0
      case 0xCC: // read NTC1
      case 0xCD: // read NTC2
      case 0xCE: // read NTC3
      case 0xCF: // read outputs
      case 0xD0: // read inputs
      case 0xD1: // read fan level
      case 0xD2: // read all values
        print('message received, command: $command');
        break;
      default:
        print('unknown serial command received');
        break;
    }
  }

  void _setTxEnable(bool value) {
    uartModeTx?.write(value);
    _pinUartModeTxState.value = value;
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
    print('>>>> $hexStr');

    _currentSerialMessage.value = m;
    update();

    await _serialService.sendMessage(m, setTxEnable: _setTxEnable);

    _sentData.add(bytes);
    if (_sentData.length > 50) _sentData.removeAt(0);
    update();
  }

  Future<void> sendSerialMessageFromStack() async {
    if (_messageStack.isNotEmpty) {
      print('Taking message from stack (${_messageStack.length} remaining)');
      SerialMessage m = _messageStack.removeAt(0);
      await sendSerialMessage(m);
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

  Future<void> runSerialLoop() async {
    if (!allowSerialLoop) return;

    _processingSerialLoop.value = true;
    update();

    // Poll all extension devices for inputs and outputs
    for (final deviceId in deviceIds.where((e) => e != mainboardId)) {
      // Read outputs
      await sendSerialMessage(SerialMessage(device: deviceId, command: 0x69));
      await waitForSerialResponse();

      // Read inputs
      await sendSerialMessage(SerialMessage(device: deviceId, command: 0x67));
      await waitForSerialResponse();
    }

    // Process any queued messages
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
      // Restart command - device cannot respond while restarting
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
        print('ERROR: Serial response timeout');
        _currentSerialMessage.value = null;
        update();
        return;
      }
    }
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

  final RxBool _invertUartTx = false.obs;
  bool get invertUartTx => _invertUartTx.value;
  void toggleInvertUartTx() {
    _invertUartTx.value = !_invertUartTx.value;
    print('UART TX Invert: ${_invertUartTx.value}');
    update();
  }
  //endregion

  /*
  late final ConnectivityService _connectivityService;
  late final GpioController _gpioController;
  late final MainController _mainController;

  @override
  void onInit() {
    super.onInit();
    _connectivityService = Get.find<ConnectivityService>();
    _gpioController = Get.find<GpioController>();
    _mainController = Get.find<MainController>();

    _syncInitialValues();

    _setupEverListeners();
  }

  void _syncInitialValues() {
    _isOnline.value = _connectivityService.isConnected;
    _isGpioReady.value = _gpioController.initialized;
    _allowSerialLoop.value = _gpioController.allowSerialLoopRx.value;
    _acUnitList.assignAll(_mainController.acUnitList);
  }

  void _setupEverListeners() {
    ever(_connectivityService.isConnectedRx, (isConnected) {
      _isOnline.value = isConnected;
      update();
    });

    ever(_gpioController.obs, (_) {
      _isGpioReady.value = _gpioController.initialized;
      _allowSerialLoop.value = _gpioController.allowSerialLoopRx.value;
      update();
    });

    ever(_mainController.obs, (_) {
      _acUnitList.assignAll(_mainController.acUnitList);
      _smokeDetection.value = _mainController.smokeDetectionRx.value;
      _waterLeak.value = _mainController.waterLeakRx.value;
      _frontDoorOpen.value = _mainController.frontDoorOpenRx.value;
      _backDoorOpen.value = _mainController.backDoorOpenRx.value;
      _serviceDoorOpen.value = _mainController.serviceDoorOpenRx.value;
      update();
    });
  }

  final RxBool _isOnline = false.obs;
  bool get isOnline => _isOnline.value;

  final RxBool _isGpioReady = false.obs;
  bool get isGpioReady => _isGpioReady.value;

  final RxList<AcUnit> _acUnitList = <AcUnit>[].obs;
  List<AcUnit> get acUnitList => _acUnitList;

  final RxBool _smokeDetection = false.obs;
  bool get smokeDetection => _smokeDetection.value;

  final RxBool _waterLeak = false.obs;
  bool get waterLeak => _waterLeak.value;

  final RxBool _frontDoorOpen = false.obs;
  bool get frontDoorOpen => _frontDoorOpen.value;

  final RxBool _backDoorOpen = false.obs;
  bool get backDoorOpen => _backDoorOpen.value;

  final RxBool _serviceDoorOpen = false.obs;
  bool get serviceDoorOpen => _serviceDoorOpen.value;

  final RxBool _allowSerialLoop = false.obs;
  bool get allowSerialLoop => _allowSerialLoop.value;

  List<SecuritySwitch> get securitySwitchList => [
    SecuritySwitch(id: 'smoke', title: 'Duman Sensörü', status: smokeDetection),
    SecuritySwitch(id: 'su', title: 'Su Kaçağı', status: waterLeak),
    SecuritySwitch(id: 'onkapi', title: 'Ön Kapı', status: frontDoorOpen),
    SecuritySwitch(id: 'arkakapi', title: 'Arka Kapı', status: backDoorOpen),
    SecuritySwitch(
      id: 'servis',
      title: 'Servis Kapısı',
      status: serviceDoorOpen,
    ),
  ];

  void toggleSerialLoop() {
    if (_gpioController.allowSerialLoop) {
      _gpioController.turnOffSerialLoop();
    } else {
      _gpioController.turnOnSerialLoop();
    }
  }

  void sendSerialTestSignal() => _mainController.sendTestSignal();

  void serialCommand({int? deviceId, int? command}) {
    _gpioController.addToSerialMessageStack(
      SerialMessage(device: deviceId ?? 0x01, command: command ?? 0x065),
    );
  }

  Future<void> buzzBeep() async {
    await _gpioController.buzzerBeep();
  }

*/
}
