import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:rack_sense/app/core/utils/common_utils.dart';

const int kStartByte = 0x3A;
const List<int> kStopBytes = [0x0D, 0x0A];
const String kSserialPort = '/dev/ttyS0';
const int kSerialAcknowledgementDelay = 91;
const int kSerialLoopDelay = 10000;
const int kNormalMessageLength = 9;
const int kSerialNumberMessageLength = 21;
const int kVersionMessageLength = 28;

class SerialService {
  SerialPort? _serialPort;
  SerialPortReader? _serialPortReader;
  StreamSubscription<Uint8List>? _messageSubscription;
  final SerialMessageHandler _handler = SerialMessageHandler();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  bool get isLinux => Platform.isLinux;

  Stream<Uint8List> get onMessage => _handler.onMessage;

  Future<bool> initialize() async {
    if (!isLinux) return false;
    if (_initialized) return true;

    try {
      _serialPort = SerialPort(kSserialPort);
      _serialPort!.openReadWrite();

      final config = SerialPortConfig();
      config.baudRate = 9600;
      config.bits = 8;
      config.parity = 0;
      config.stopBits = 1;
      config.setFlowControl(SerialPortFlowControl.none);
      _serialPort!.config = config;

      await CU.wait(500);

      _messageSubscription?.cancel();
      _messageSubscription = _serialPortReader!.stream.listen(
        (Uint8List data) {
          _handler.onDataReceived(data);
        },
        onError: (error) {
          // error handled by caller
        },
        cancelOnError: false,
      );

      await CU.wait(500);

      _initialized = true;
      return true;
    } catch (e) {
      _initialized = false;
      return false;
    }
  }

  Future<void> sendMessage(
    SerialMessage message, {
    required bool Function(bool) setTxEnable,
  }) async {
    if (!_initialized || _serialPort == null) return;

    final bytes = message.toBytes();

    // TX Enable: false = transmit mode, true = receive mode (inverted)
    setTxEnable(false);
    await CU.wait(1);

    try {
      _serialPort!.write(bytes);
    } catch (_) {
      // write error
    }

    await CU.wait(10);
    setTxEnable(true);
  }

  void dispose() {
    _messageSubscription?.cancel();
    _serialPortReader?.close();
    if (_serialPort?.isOpen ?? false) {
      _serialPort!.close();
    }
    _serialPort?.dispose();
    _handler.dispose();
    _initialized = false;
  }
}

class SerialMessageHandler {
  final List<int> _buffer = [];
  final StreamController<Uint8List> _controller =
      StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get onMessage => _controller.stream;

  int _getMessageLength(List<int> buffer) {
    if (buffer.length >= 3) {
      switch (buffer[2]) {
        case 0xCA: // serial number
          return kSerialNumberMessageLength;
        case 0xCB: // hardware version
        case 0xCC: // firmware version
          return kVersionMessageLength;
        default:
          return kNormalMessageLength;
      }
    }
    return kNormalMessageLength;
  }

  void onDataReceived(Uint8List data) {
    for (var byte in data) {
      _buffer.add(byte);

      int expectedLength = _getMessageLength(_buffer);

      if (_buffer.length >= expectedLength) {
        if (_buffer[0] == kStartByte &&
            _buffer[expectedLength - 2] == kStopBytes[0] &&
            _buffer[expectedLength - 1] == kStopBytes[1]) {
          Uint8List message = Uint8List.fromList(
            _buffer.sublist(0, expectedLength),
          );
          _controller.add(message);
          _buffer.clear();
        } else {
          _buffer.removeAt(0);
        }
      }
    }
  }

  void dispose() {
    _buffer.clear();
    _controller.close();
  }
}

class SerialMessage {
  int device;
  int command;
  int index;
  int arg;

  SerialMessage({
    required this.device,
    required this.command,
    this.index = 0x00,
    this.arg = 0x00,
  });

  List<int> toBytesWithCrc() {
    List<int> dataForCrc = [device, command, index, arg];
    List<int> crcBytes = SerialUtils.getCrcBytes(
      Uint8List.fromList(dataForCrc),
    );

    return [
      kStartByte,
      device,
      command,
      index,
      arg,
      ...crcBytes,
      ...kStopBytes,
    ];
  }

  Uint8List toBytes() => Uint8List.fromList(toBytesWithCrc());

  String toLog() => SerialUtils.bytesToHex(toBytes());

  @override
  String toString() =>
      'SerialMessage(device: 0x${device.toRadixString(16).padLeft(2, '0')}, '
      'cmd: 0x${command.toRadixString(16).padLeft(2, '0')}, '
      'idx: 0x${index.toRadixString(16).padLeft(2, '0')}, '
      'arg: 0x${arg.toRadixString(16).padLeft(2, '0')})';
}

class SerialUtils {
  static const List<int> _crcTable = [
    0x0000,
    0x1021,
    0x2042,
    0x3063,
    0x4084,
    0x50a5,
    0x60c6,
    0x70e7,
    0x8108,
    0x9129,
    0xa14a,
    0xb16b,
    0xc18c,
    0xd1ad,
    0xe1ce,
    0xf1ef,
  ];

  static int serialUartCrc16(Uint8List data) {
    int crc = 0xFFFF;

    for (int i = 0; i < data.length; i++) {
      int byte = data[i];
      crc = (crc << 4) ^ _crcTable[((crc >> 12) ^ (byte >> 4)) & 0x0F];
      crc = (crc << 4) ^ _crcTable[((crc >> 12) ^ (byte & 0x0F)) & 0x0F];
    }

    return crc & 0xFFFF;
  }

  static List<int> getCrcBytes(Uint8List data) {
    int crc = serialUartCrc16(data);
    int firstByte = crc % 256; // CRC_L (low byte)
    int secondByte = crc ~/ 256; // CRC_H (high byte)
    return [firstByte, secondByte];
  }

  static bool validateCrc(List<int> rawData) {
    int command = rawData[2];

    int crcDataLength;
    switch (command) {
      case 0xCA:
        crcDataLength = 17;
        break;
      case 0xCB:
      case 0xCC:
        crcDataLength = 24;
        break;
      default:
        crcDataLength = 5;
    }

    List<int> dataForCrc = rawData.sublist(1, crcDataLength);
    List<int> expectedCrcBytes = getCrcBytes(Uint8List.fromList(dataForCrc));
    List<int> receivedCrcBytes = rawData.sublist(
      crcDataLength,
      crcDataLength + 2,
    );

    return receivedCrcBytes[0] == expectedCrcBytes[0] &&
        receivedCrcBytes[1] == expectedCrcBytes[1];
  }

  static String bytesToHex(Uint8List bytes) {
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  static List<bool> parseStates(int value) {
    List<bool> states = [];
    for (int i = 0; i < 6; i++) {
      states.add((value & (1 << i)) != 0);
    }
    return states;
  }

  static String bytesToAscii(List<int> bytes) {
    return String.fromCharCodes(bytes).replaceAll(RegExp(r'[^\x20-\x7E]'), '?');
  }
}
