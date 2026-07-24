import 'package:get/get.dart';
import 'package:rack_sense/app/core/routes/routes.dart';
import 'package:rack_sense/app/presentation/screens/alarm/alarm_screen.dart';
import 'package:rack_sense/app/presentation/screens/camera/camera_screen.dart';
import 'package:rack_sense/app/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:rack_sense/app/presentation/screens/monitor/monitor_screen.dart';
import 'package:rack_sense/app/presentation/screens/settings/system_settings_screen.dart';
import 'package:rack_sense/app/presentation/screens/sync/sync_screen.dart';

final List<GetPage> getPages = [
  GetPage(name: Routes.dashboard, page: () => DashboardScreen()),
  GetPage(name: Routes.monitor, page: () => MonitorScreen()),
  GetPage(name: Routes.alarm, page: () => AlarmScreen()),
  GetPage(name: Routes.camera, page: () => CameraScreen()),
  GetPage(name: Routes.sync, page: () => SyncScreen()),
  GetPage(name: Routes.settings, page: () => SystemSettingsScreen()),
];
