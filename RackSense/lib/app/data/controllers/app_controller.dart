import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/gpio_controller.dart';
import 'package:rack_sense/app/data/controllers/main_controller.dart';
import 'package:rack_sense/app/data/models/ac_unit.dart';
import 'package:rack_sense/app/data/services/connectivity_service.dart';

class AppController extends GetxController {
  late final ConnectivityService _connectivityService;
  late final GpioController _gpioController;
  late final MainController _mainController;

  @override
  void onInit() {
    super.onInit();
    _connectivityService = Get.find<ConnectivityService>();
    _gpioController = Get.find<GpioController>();
    _mainController = Get.find<MainController>();

    _syncInitialValues();

    _setupEverListeners();
  }

  void _syncInitialValues() {
    _isGpioReady.value = _gpioController.initialized;
    _acUnitList.assignAll(_mainController.acUnitList);
  }

  void _setupEverListeners() {
    ever(_gpioController.obs, (_) {
      _isGpioReady.value = _gpioController.initialized;
      update();
    });

    ever(_mainController.obs, (_) {
      _acUnitList.assignAll(_mainController.acUnitList);
      update();
    });
  }

  bool get isOnline => _connectivityService.isConnected;

  final RxBool _isGpioReady = false.obs;
  bool get isGpioReady => _isGpioReady.value;

  final RxList<AcUnit> _acUnitList = <AcUnit>[].obs;
  List<AcUnit> get acUnitList => _acUnitList;
}
