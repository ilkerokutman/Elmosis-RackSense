import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/data/controllers/gpio_controller.dart';
import 'package:rack_sense/app/data/controllers/main_controller.dart';
import 'package:rack_sense/app/data/controllers/sync_controller.dart';
import 'package:rack_sense/app/data/services/connectivity_service.dart';
import 'package:rack_sense/app/data/services/database_service.dart';
import 'package:rack_sense/app/data/services/serial_service.dart';

class InitialBindings extends Bindings {
  @override
  Future<void> dependencies() async {
    print("Dependency Injection: Starting Database Service init");
    await Get.putAsync(() async => DatabaseService(), permanent: true);
    print("Dependency Injection: Database Service initialized");

    // TODO: ApiProvider

    print("Dependency Injection: Starting Connectivity Service init");
    final connectivityService = ConnectivityService();
    await connectivityService.initialize();
    await Get.putAsync(() async => connectivityService, permanent: true);
    print("Dependency Injection: Connectivity Service initialized");

    print("Dependency Injection: Starting Serial init");
    await Get.putAsync(() async => SerialService(), permanent: true);
    final serialInitResult = await Get.find<SerialService>().initialize();
    print("Dependency Injection: Serial Initialization: $serialInitResult");

    print("Dependency Injection: Starting GPIO init");
    await Get.putAsync(() async => GpioController(), permanent: true);
    await Get.find<GpioController>().initialize();
    print("Dependency Injection: GPIO init completed");

    print("Dependency Injection: Starting SYNC init");
    await Get.putAsync(() async => SyncController(), permanent: true);
    print("Dependency Injection: SYNC init completed");

    print("Dependency Injection: Starting MAIN init");
    await Get.putAsync(() async => MainController(), permanent: true);
    Get.find<MainController>().initializeAcUnitList();
    print("Dependency Injection: MAIN init completed");

    print("Dependency Injection: Starting APP init");
    await Get.putAsync(() async => AppController(), permanent: true);
    print("Dependency Injection: APP init completed");
  }
}
