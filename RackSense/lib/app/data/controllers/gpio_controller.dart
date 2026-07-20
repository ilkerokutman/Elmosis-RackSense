// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;

import 'package:dart_periphery/dart_periphery.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/core/utils/common_utils.dart';

class GpioController extends GetxController {
  //
  @override
  void onInit() {
    super.onInit();
    initialize();
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

  Future<void> initialize() async {
    if (!Platform.isLinux) {
      return;
    }

    print('GPIO: Starting init');

    try {
      _serPin = GPIO(serPin, GPIOdirection.gpioDirOut);

      _srclkPin = GPIO(srclkPin, GPIOdirection.gpioDirOut);

      _rclkPin = GPIO(rclkPin, GPIOdirection.gpioDirOut);

      // _txEnablePin = GPIO(txEnablePin, GPIOdirection.gpioDirOut);

      // _buzzerPin = GPIO(buzzerPin, GPIOdirection.gpioDirOut);

      // _fanPin = GPIO(fanPin, GPIOdirection.gpioDirOut);

      for (final int pin in inputPins) {
        final gpio = GPIO(pin, GPIOdirection.gpioDirIn);
        _inputPins[pin] = gpio;
      }

      for (final int pin in buttonPins) {
        final gpio = GPIO(pin, GPIOdirection.gpioDirIn);
        _buttonPins[pin] = gpio;
      }

      // _spiAdc = SPI(0, 0, SPImode.mode0, 1000000);

      _initCompleted.value = true;
      update();
      print(
        'GPIO: Initialization complete. Inputs: ${_inputPins.length}, Buttons: ${_buttonPins.length}, SPI: ${_spiAdc != null}',
      );
    } on Exception catch (e) {
      print('GPIO init error: ${e.toString()}');
    }
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
    super.dispose();
  }
}
