import 'package:get/get.dart';
import 'package:rack_sense/app/core/routes/routes.dart';
import 'package:rack_sense/app/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:rack_sense/app/presentation/screens/settings/settings_screen.dart';
import 'package:rack_sense/app/presentation/screens/sync/sync_screen.dart';

final List<GetPage> getPages = [
  GetPage(name: Routes.dashboard, page: () => DashboardScreen()),
  GetPage(name: Routes.settings, page: () => SettingsScreen()),
  GetPage(name: Routes.sync, page: () => SyncScreen()),
];
