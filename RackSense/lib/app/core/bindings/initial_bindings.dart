import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/data/controllers/gpio_controller.dart';
import 'package:rack_sense/app/data/controllers/main_controller.dart';
import 'package:rack_sense/app/data/controllers/sync_controller.dart';
import 'package:rack_sense/app/data/services/connectivity_service.dart';

class InitialBindings extends Bindings {
  @override
  Future<void> dependencies() async {
    // TODO: DbProvider
    // TODO: ApiProvider

    final connectivityService = ConnectivityService();
    await connectivityService.initialize();
    await Get.putAsync(() async => connectivityService, permanent: true);

    print("Dependency Injection: Starting GPIO init");
    await Get.putAsync(() async => GpioController(), permanent: true);
    await Get.find<GpioController>().initialize();
    print("Dependency Injection: GPIO init completed");

    await Get.putAsync(() async => SyncController(), permanent: true);

    await Get.putAsync(() async => MainController(), permanent: true);

    await Get.putAsync(() async => AppController(), permanent: true);
  }
}
