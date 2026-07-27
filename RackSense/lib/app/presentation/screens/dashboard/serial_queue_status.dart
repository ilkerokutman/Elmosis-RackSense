import 'package:flutter/material.dart';
import 'package:rack_sense/app/core/constants/serial.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/data/services/serial_service.dart';

class SerialQueueStatusWidget extends StatelessWidget {
  const SerialQueueStatusWidget({
    super.key,
    required this.controller,
    this.pendingTemperature,
  });

  final AppController controller;
  final int? pendingTemperature;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = _status();
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Icon(status.icon, color: status.color.resolve(scheme)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status.message,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: status.color.resolve(scheme),
              ),
            ),
          ),
          if (status.isInProgress)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: status.color.resolve(scheme),
              ),
            ),
        ],
      ),
    );
  }

  _QueueStatus _status() {
    if (pendingTemperature != null) {
      return _QueueStatus(
        icon: Icons.tune,
        message: '$pendingTemperature°C isteği hazırlanıyor…',
        color: _StatusColor.warning,
        isInProgress: true,
      );
    }

    final current = controller.currentSerialMessage;
    if (current != null) {
      final isConnectivityProbe = current.command == SerialKeys.cmdCommTest;
      final isUserCommand = _isUserCommand(current);
      return _QueueStatus(
        icon: isConnectivityProbe
            ? Icons.settings_ethernet
            : isUserCommand
            ? Icons.upload
            : Icons.sync,
        message: isConnectivityProbe
            ? 'Klima #${current.device} bağlantısı denetleniyor…'
            : isUserCommand
            ? '${_commandLabel(current)} gönderiliyor…'
            : 'Klima #${current.device} verileri okunuyor…',
        color: isUserCommand ? _StatusColor.warning : _StatusColor.primary,
        isInProgress: true,
      );
    }

    final queued = controller.messageStack;
    if (queued.isNotEmpty) {
      final next = queued.first;
      return _QueueStatus(
        icon: Icons.schedule,
        message: 'Sırada: ${_commandLabel(next)} (${queued.length} bekliyor)',
        color: _StatusColor.warning,
        isInProgress: false,
      );
    }

    return const _QueueStatus(
      icon: Icons.check_circle_outline,
      message: 'Hazır',
      color: _StatusColor.muted,
      isInProgress: false,
    );
  }

  bool _isUserCommand(SerialMessage message) =>
      message.command < SerialKeys.cmdReadValue &&
      message.command != SerialKeys.cmdCommTest;

  String _commandLabel(SerialMessage message) {
    final device = 'Klima #${message.device}';
    return switch (message.command) {
      SerialKeys.cmdSetValue =>
        '$device için ${message.arg.toSigned(8)}°C ayarı',
      SerialKeys.cmdTurnOn => '$device çalıştırma',
      SerialKeys.cmdTurnOff => '$device durdurma',
      SerialKeys.cmdReset => '$device yeniden başlatma',
      _ => '$device işlemi',
    };
  }
}

class _QueueStatus {
  const _QueueStatus({
    required this.icon,
    required this.message,
    required this.color,
    required this.isInProgress,
  });

  final IconData icon;
  final String message;
  final _StatusColor color;
  final bool isInProgress;
}

enum _StatusColor {
  primary,
  warning,
  muted;

  Color resolve(ColorScheme scheme) => switch (this) {
    _StatusColor.primary => scheme.primary,
    _StatusColor.warning => scheme.tertiary,
    _StatusColor.muted => scheme.onSurfaceVariant,
  };
}
