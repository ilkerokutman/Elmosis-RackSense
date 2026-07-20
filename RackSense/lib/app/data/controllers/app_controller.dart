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
    _isOnline.value = _connectivityService.isConnected;
    _isGpioReady.value = _gpioController.initialized;
    _acUnitList.assignAll(_mainController.acUnitList);
  }

  void _setupEverListeners() {
    ever(_connectivityService.isConnectedRx, (isConnected) {
      _isOnline.value = isConnected;
      update();
    });

    ever(_gpioController.obs, (_) {
      _isGpioReady.value = _gpioController.initialized;
      update();
    });

    ever(_mainController.obs, (_) {
      _acUnitList.assignAll(_mainController.acUnitList);
      update();
    });
  }

  final RxBool _isOnline = false.obs;
  bool get isOnline => _isOnline.value;

  final RxBool _isGpioReady = false.obs;
  bool get isGpioReady => _isGpioReady.value;

  final RxList<AcUnit> _acUnitList = <AcUnit>[].obs;
  List<AcUnit> get acUnitList => _acUnitList;
}
