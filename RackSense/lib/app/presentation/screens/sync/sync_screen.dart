import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/sync_controller.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';

class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SyncController>(
      builder: (controller) => AppScaffold(
        selectedIndex: 4,
        title: 'RackSense: Senkronizasyon',
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Veri Eşitleme',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Yerel kayıtlar eşitleme için hazır tutulur.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatusCard(
                    icon: Icons.history_outlined,
                    label: 'Son eşitleme',
                    value: _lastSyncLabel(controller.lastSyncAt),
                  ),
                  _StatusCard(
                    icon: Icons.cloud_upload_outlined,
                    label: 'Gönderilmemiş veri',
                    value: '${controller.unsentDataCount}',
                  ),
                  _StatusCard(
                    icon: Icons.schedule_outlined,
                    label: 'Eşitlemeye kalan süre',
                    value: _durationLabel(
                      controller.nextSyncAt.difference(DateTime.now()),
                    ),
                  ),
                  _StatusCard(
                    icon: Icons.error_outline,
                    label: 'Hatalı kayıt',
                    value: '${controller.failedDataCount}',
                    valueColor: controller.failedDataCount > 0
                        ? Colors.red
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Eşitleme İşlemleri',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sunucu uç noktası tanımlandığında bu işlemler '
                        'verileri güvenli olarak gönderir.',
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: controller.isRefreshing
                                ? null
                                : () => _prepareSync(context, controller),
                            icon: const Icon(Icons.sync),
                            label: const Text('Şimdi eşitle'),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                controller.isRefreshing ||
                                    controller.failedDataCount == 0
                                ? null
                                : () => _prepareRetry(context, controller),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Hatalıları yeniden dene'),
                          ),
                          IconButton(
                            tooltip: 'Kayıtları yenile',
                            onPressed: controller.isRefreshing
                                ? null
                                : controller.refreshStatus,
                            icon: controller.isRefreshing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _prepareSync(
    BuildContext context,
    SyncController controller,
  ) async {
    await controller.prepareSyncNow();
    if (!context.mounted) return;
    _showEndpointWaitingMessage(context);
  }

  Future<void> _prepareRetry(
    BuildContext context,
    SyncController controller,
  ) async {
    await controller.prepareRetryNow();
    if (!context.mounted) return;
    _showEndpointWaitingMessage(context);
  }

  void _showEndpointWaitingMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sunucu uç noktası bekleniyor.')),
    );
  }

  String _lastSyncLabel(DateTime? lastSyncAt) {
    if (lastSyncAt == null) return 'Henüz eşitlenmedi';
    return '${_twoDigits(lastSyncAt.day)}.${_twoDigits(lastSyncAt.month)} '
        '${_twoDigits(lastSyncAt.hour)}:${_twoDigits(lastSyncAt.minute)}';
  }

  String _durationLabel(Duration duration) {
    if (duration.isNegative) return 'Hazır';
    final hours = _twoDigits(duration.inHours);
    final minutes = _twoDigits(duration.inMinutes.remainder(60));
    final seconds = _twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: valueColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
