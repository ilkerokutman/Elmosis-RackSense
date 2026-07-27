import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/alarm_controller.dart';
import 'package:rack_sense/app/data/models/alarm_state.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  static const _mockCameraStreamUrl = 'http://localhost:8080/video_feed';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AlarmController>(
      builder: (alarmController) {
        final openDoors = alarmController.alarms
            .where(
              (alarm) => alarm.isActive && _doorKeys.contains(alarm.config.key),
            )
            .toList(growable: false);
        return AppScaffold(
          selectedIndex: 3,
          title: 'RackSense: Kamera ve Güvenlik',
          body: LayoutBuilder(
            builder: (context, constraints) {
              final camera = _LiveCameraPanel(streamUrl: _mockCameraStreamUrl);
              final security = _SecurityPanel(openDoors: openDoors);

              return Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(flex: 3, child: camera),

                    SizedBox(width: 280, child: security),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

const _doorKeys = {'front_door', 'rear_door', 'service_door'};

class _LiveCameraPanel extends StatelessWidget {
  const _LiveCameraPanel({required this.streamUrl});

  final String streamUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.videocam_outlined),
                const SizedBox(width: 8),
                Text(
                  'Canlı kamera',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                const Icon(Icons.circle, color: Colors.red, size: 12),
                const SizedBox(width: 6),
                Text(
                  'CANLI',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: Colors.black,
              child: _MjpegView(streamUrl: streamUrl),
            ),
          ),
        ],
      ),
    );
  }
}

class _MjpegView extends StatefulWidget {
  const _MjpegView({required this.streamUrl});

  final String streamUrl;

  @override
  State<_MjpegView> createState() => _MjpegViewState();
}

class _MjpegViewState extends State<_MjpegView> {
  static const _startMarker = 0xd8;
  static const _endMarker = 0xd9;
  static const _markerPrefix = 0xff;
  static const _maximumFrameSize = 5 * 1024 * 1024;

  final HttpClient _client = HttpClient();
  BytesBuilder? _frameBuffer;
  StreamSubscription<List<int>>? _subscription;
  Uint8List? _image;
  Object? _error;
  int? _previousByte;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      final request = await _client.getUrl(Uri.parse(widget.streamUrl));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      _subscription = response.listen(
        _readChunk,
        onError: _handleError,
        onDone: () {
          if (_image == null) _handleError('Kamera akışı sonlandı');
        },
        cancelOnError: true,
      );
    } on Object catch (error) {
      _handleError(error);
    }
  }

  void _readChunk(List<int> chunk) {
    for (final byte in chunk) {
      if (_frameBuffer == null) {
        if (_previousByte == _markerPrefix && byte == _startMarker) {
          _frameBuffer = BytesBuilder(copy: false)
            ..addByte(_markerPrefix)
            ..addByte(_startMarker);
        }
      } else {
        _frameBuffer!.addByte(byte);
        if (_frameBuffer!.length > _maximumFrameSize) {
          _frameBuffer = null;
          _handleError('Kamera karesi çok büyük');
          return;
        }
        if (_previousByte == _markerPrefix && byte == _endMarker) {
          final image = _frameBuffer!.takeBytes();
          _frameBuffer = null;
          if (mounted) setState(() => _image = image);
        }
      }
      _previousByte = byte;
    }
  }

  void _handleError(Object error) {
    if (mounted) setState(() => _error = error);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _client.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return const _CameraStateMessage(
        icon: Icons.videocam_off_outlined,
        message: 'Kamera akışına bağlanılamadı',
      );
    }
    if (_image == null) {
      return const _CameraStateMessage(
        icon: Icons.hourglass_top_rounded,
        message: 'Kamera bağlantısı kuruluyor...',
      );
    }
    return Image.memory(_image!, fit: BoxFit.contain, gaplessPlayback: true);
  }
}

class _SecurityPanel extends StatelessWidget {
  const _SecurityPanel({required this.openDoors});

  final List<AlarmState> openDoors;

  @override
  Widget build(BuildContext context) {
    final hasOpenDoor = openDoors.isNotEmpty;
    final statusColor = hasOpenDoor ? Colors.red : Colors.green;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: statusColor),
                const SizedBox(width: 8),
                Text('Güvenlik', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: hasOpenDoor
                  ? ListView.separated(
                      itemCount: openDoors.length,
                      separatorBuilder: (_, _) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final door = openDoors[index];
                        return Row(
                          children: [
                            const Icon(
                              Icons.door_front_door_outlined,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                door.config.displayLabel,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            const Text(
                              'AÇIK',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : const _SecurityClearState(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraStateMessage extends StatelessWidget {
  const _CameraStateMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 40),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _SecurityClearState extends StatelessWidget {
  const _SecurityClearState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, color: Colors.green, size: 44),
          SizedBox(height: 12),
          Text('Tüm kapılar kapalı'),
        ],
      ),
    );
  }
}
