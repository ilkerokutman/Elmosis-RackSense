import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/data/models/temperature_sample.dart';
import 'package:rack_sense/app/data/repositories/telemetry_repository.dart';
import 'package:rack_sense/app/data/services/database_service.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';
import 'package:rack_sense/app/presentation/screens/monitor/widgets/monitor_card_widget.dart';
import 'package:rack_sense/app/presentation/screens/monitor/widgets/temperature_history_chart.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  late final TelemetryRepository _telemetryRepository;
  late Future<List<TemperatureSample>> _history;
  late Future<Duration> _dailyRuntime;
  late DateTime _from;
  late DateTime _until;
  Timer? _refreshTimer;
  _MonitorRange _range = _MonitorRange.fiveMinutes;

  @override
  void initState() {
    super.initState();
    _telemetryRepository = TelemetryRepository(Get.find<DatabaseService>());
    _loadData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => mounted ? setState(_loadData) : null,
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadData() {
    _until = DateTime.now();
    _from = _until.subtract(_range.duration);
    _history = _telemetryRepository.temperatureHistory(from: _from);
    _dailyRuntime = _telemetryRepository.runtimeForToday();
  }

  void _selectRange(_MonitorRange range) {
    setState(() {
      _range = range;
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 1,
      title: 'RackSense: İzleme',
      body: Row(
        children: [
          Expanded(child: _buildGraphCard(context)),
          SizedBox(width: 240, child: _buildLiveCard(context)),
        ],
      ),
    );
  }

  Widget _buildGraphCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sıcaklık Geçmişi',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                _Legend(color: scheme.primary, label: 'Ortam (NTC 1)'),
                const SizedBox(width: 16),
                _Legend(color: scheme.tertiary, label: 'Hedef sıcaklık'),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<_MonitorRange>(
              segments: _MonitorRange.values
                  .map(
                    (range) =>
                        ButtonSegment(value: range, label: Text(range.label)),
                  )
                  .toList(growable: false),
              selected: {_range},
              onSelectionChanged: (selection) => _selectRange(selection.first),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<TemperatureSample>>(
                future: _history,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Grafik verisi okunamadı'));
                  }
                  return TemperatureHistoryChart(
                    samples: snapshot.data ?? const [],
                    from: _from,
                    until: _until,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveCard(BuildContext context) {
    return GetBuilder<AppController>(
      builder: (controller) {
        final activeCount = controller.units.values
            .where((unit) => unit.isConnected && unit.isRunning)
            .length;
        return Card(
          margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  'Canlı Özet',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    MonitorCardWidget(
                      label: 'Ortam',
                      value:
                          controller.rackTemperature?.toStringAsFixed(0) == null
                          ? '--°C'
                          : '${controller.rackTemperature!.toStringAsFixed(0)}°C',
                    ),
                    const MonitorCardWidget(label: 'Üfleme', value: '--°C'),
                    const MonitorCardWidget(label: 'Nem', value: '--%'),
                    const MonitorCardWidget(
                      label: 'Hava kalitesi',
                      value: '--',
                    ),
                    FutureBuilder<Duration>(
                      future: _dailyRuntime,
                      builder: (context, snapshot) => MonitorCardWidget(
                        label: 'Günlük çalışma',
                        value: _formatDuration(snapshot.data ?? Duration.zero),
                      ),
                    ),
                    MonitorCardWidget(
                      label: 'Aktif klima',
                      value: '$activeCount / ${controller.units.length}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

enum _MonitorRange {
  fiveMinutes(Duration(minutes: 5), '5 dk'),
  hour(Duration(hours: 1), '1 saat'),
  day(Duration(hours: 24), '24 saat');

  const _MonitorRange(this.duration, this.label);

  final Duration duration;
  final String label;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 20, height: 3, color: color),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
