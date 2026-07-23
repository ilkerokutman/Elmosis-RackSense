import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/core/constants/serial.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/data/services/serial_service.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AppController _appController;
  late final SerialService _serialService;
  StreamSubscription<Uint8List>? _messageSubscription;

  int? _deviceStatus;
  bool? _isRunning;
  int? _setTemperature;
  int? _ntc0;
  int? _ntc1;
  int? _ntc2;
  int? _ntc3;
  int? _outputs;
  int? _inputs;
  int? _fanLevel;

  bool _isSetTempBusy = false;
  bool _isOnOffBusy = false;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _serialService = Get.find<SerialService>();
    _messageSubscription = _serialService.onMessage.listen(_onSerialMessage);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _onSerialMessage(Uint8List data) {
    if (data.length < kNormalMessageLength) return;

    final command = data[2];
    final args = data[4];

    if (command == SerialKeys.cmdReadAll &&
        data.length == kReadAllMessageLength) {
      final values = data.sublist(3, data.length - 2);
      if (values.length < 10) return;
      setState(() {
        _deviceStatus = values[1];
        _isRunning = values[1] != 0;
        _setTemperature = values[2].toSigned(8);
        _ntc0 = values[3].toSigned(8);
        _ntc1 = values[4].toSigned(8);
        _ntc2 = values[5].toSigned(8);
        _ntc3 = values[6].toSigned(8);
        _outputs = values[7];
        _inputs = values[8];
        _fanLevel = values[9].toSigned(8);
      });
      return;
    }

    setState(() {
      switch (command) {
        case SerialKeys.cmdSetValue:
          _setTemperature = args.toSigned(8);
          _isSetTempBusy = false;
        case SerialKeys.cmdReadValue:
          _setTemperature = args.toSigned(8);
        case SerialKeys.cmdReadNtc0:
          _ntc0 = args.toSigned(8);
        case SerialKeys.cmdReadNtc1:
          _ntc1 = args.toSigned(8);
        case SerialKeys.cmdReadNtc2:
          _ntc2 = args.toSigned(8);
        case SerialKeys.cmdReadNtc3:
          _ntc3 = args.toSigned(8);
        case SerialKeys.cmdReadOutputs:
          _outputs = args;
        case SerialKeys.cmdReadInputs:
          _inputs = args;
        case SerialKeys.cmdReadFanLevel:
          _fanLevel = args.toSigned(8);
        case SerialKeys.cmdTurnOn:
          _isRunning = args != 0;
          _isOnOffBusy = false;
        case SerialKeys.cmdTurnOff:
          _isRunning = args != 0;
          _isOnOffBusy = false;
      }
    });
  }

  Future<void> _changeSetTemperature(int delta) async {
    if (_isSetTempBusy) return;
    final newValue = ((_setTemperature ?? 25) + delta).clamp(-128, 127);
    setState(() {
      _setTemperature = newValue;
      _isSetTempBusy = true;
    });

    await _appController.sendSerialMessage(
      SerialMessage(
        device: SerialKeys.device1,
        command: SerialKeys.cmdSetValue,
        arg: newValue & 0xFF,
      ),
    );
    await _appController.waitForSerialResponse();

    if (mounted) {
      setState(() => _isSetTempBusy = false);
    }
  }

  Future<void> _toggleOnOff(bool turnOn) async {
    if (_isOnOffBusy || !mounted) return;
    setState(() => _isOnOffBusy = true);

    await _appController.sendSerialMessage(
      SerialMessage(
        device: SerialKeys.device1,
        command: turnOn ? SerialKeys.cmdTurnOn : SerialKeys.cmdTurnOff,
      ),
    );
    await _appController.waitForSerialResponse();

    if (mounted) {
      setState(() => _isOnOffBusy = false);
    }
  }

  Future<void> _refresh() async {
    await _appController.sendSerialMessage(
      SerialMessage(device: SerialKeys.device1, command: SerialKeys.cmdReadAll),
    );
    await _appController.waitForSerialResponse();
  }

  Widget _buildValueRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value ?? '--',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outputsText = _outputs == null
        ? null
        : '0b${_outputs!.toRadixString(2).padLeft(8, '0')}';
    final inputsText = _inputs == null
        ? null
        : '0b${_inputs!.toRadixString(2).padLeft(8, '0')}';

    return AppScaffold(
      selectedIndex: 5,
      title: 'Ayarlar',
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Device Control (Dev Mode)',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildValueRow(
                    'Set Temperature',
                    _setTemperature == null ? null : '$_setTemperature°C',
                  ),
                  _buildValueRow('NTC0', _ntc0 == null ? null : '$_ntc0°C'),
                  _buildValueRow('NTC1', _ntc1 == null ? null : '$_ntc1°C'),
                  _buildValueRow('NTC2', _ntc2 == null ? null : '$_ntc2°C'),
                  _buildValueRow('NTC3', _ntc3 == null ? null : '$_ntc3°C'),
                  _buildValueRow(
                    'Fan Level',
                    _fanLevel == null ? null : '$_fanLevel',
                  ),
                  _buildValueRow('Outputs', outputsText),
                  _buildValueRow('Inputs', inputsText),
                  _buildValueRow(
                    'Device Status',
                    _deviceStatus == null
                        ? null
                        : '0x${_deviceStatus!.toRadixString(16).padLeft(2, '0')}',
                  ),
                  _buildValueRow(
                    'Running',
                    _isRunning == null ? null : (_isRunning! ? 'ON' : 'OFF'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Set Temperature',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _isSetTempBusy
                                  ? null
                                  : () => _changeSetTemperature(-1),
                              icon: const Icon(Icons.remove),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                _setTemperature == null
                                    ? '--°C'
                                    : '$_setTemperature°C',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                            ),
                            IconButton(
                              onPressed: _isSetTempBusy
                                  ? null
                                  : () => _changeSetTemperature(1),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isOnOffBusy || _isRunning == null
                      ? null
                      : () => _toggleOnOff(!_isRunning!),
                  child: Text(
                    _isOnOffBusy
                        ? 'Waiting...'
                        : _isRunning == true
                        ? 'Turn Off'
                        : 'Turn On',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Readings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
