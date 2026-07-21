import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/gpio_controller.dart';
import 'package:rack_sense/app/data/controllers/main_controller.dart';
import 'package:rack_sense/app/data/models/ac_unit.dart';
import 'package:rack_sense/app/data/models/security_switch.dart';
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
      _smokeDetection.value = _mainController.smokeDetectionRx.value;
      _waterLeak.value = _mainController.waterLeakRx.value;
      _frontDoorOpen.value = _mainController.frontDoorOpenRx.value;
      _backDoorOpen.value = _mainController.backDoorOpenRx.value;
      _serviceDoorOpen.value = _mainController.serviceDoorOpenRx.value;
      update();
    });
  }

  final RxBool _isOnline = false.obs;
  bool get isOnline => _isOnline.value;

  final RxBool _isGpioReady = false.obs;
  bool get isGpioReady => _isGpioReady.value;

  final RxList<AcUnit> _acUnitList = <AcUnit>[].obs;
  List<AcUnit> get acUnitList => _acUnitList;

  final RxBool _smokeDetection = false.obs;
  bool get smokeDetection => _smokeDetection.value;

  final RxBool _waterLeak = false.obs;
  bool get waterLeak => _waterLeak.value;

  final RxBool _frontDoorOpen = false.obs;
  bool get frontDoorOpen => _frontDoorOpen.value;

  final RxBool _backDoorOpen = false.obs;
  bool get backDoorOpen => _backDoorOpen.value;

  final RxBool _serviceDoorOpen = false.obs;
  bool get serviceDoorOpen => _serviceDoorOpen.value;

  List<SecuritySwitch> get securitySwitchList => [
    SecuritySwitch(id: 'smoke', title: 'Duman Sensörü', status: smokeDetection),
    SecuritySwitch(id: 'su', title: 'Su Kaçağı', status: waterLeak),
    SecuritySwitch(id: 'onkapi', title: 'Ön Kapı', status: frontDoorOpen),
    SecuritySwitch(id: 'arkakapi', title: 'Arka Kapı', status: backDoorOpen),
    SecuritySwitch(
      id: 'servis',
      title: 'Servis Kapısı',
      status: serviceDoorOpen,
    ),
  ];

  Future<void> sendSerialTestSignal() async {
    await _mainController.sendTestSignal();
  }
}
