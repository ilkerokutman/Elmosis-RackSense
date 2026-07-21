import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/gpio_controller.dart';
import 'package:rack_sense/app/data/models/ac_unit.dart';
import 'package:rack_sense/app/data/services/serial_service.dart';

class MainController extends GetxController {
  //

  final RxList<AcUnit> _acUnitList = <AcUnit>[].obs;
  RxList get acUnitListRx => _acUnitList;
  List<AcUnit> get acUnitList => _acUnitList;

  void initializeAcUnitList() {
    _acUnitList.assignAll([
      AcUnit(
        id: 0x01,
        roomTemperature: 0,
        blowTemperature: 0,
        targetTemperature: 0,
      ),
      AcUnit(
        id: 0x02,
        roomTemperature: 0,
        blowTemperature: 0,
        targetTemperature: 0,
      ),
    ]);
  }

  final RxBool _smokeDetection = false.obs;
  RxBool get smokeDetectionRx => _smokeDetection;
  bool get smokeDetection => _smokeDetection.value;

  final RxBool _waterLeak = false.obs;
  RxBool get waterLeakRx => _waterLeak;
  bool get waterLeak => _waterLeak.value;

  final RxBool _frontDoorOpen = false.obs;
  RxBool get frontDoorOpenRx => _frontDoorOpen;
  bool get frontDoorOpen => _frontDoorOpen.value;

  final RxBool _backDoorOpen = false.obs;
  RxBool get backDoorOpenRx => _backDoorOpen;
  bool get backDoorOpen => _backDoorOpen.value;

  final RxBool _serviceDoorOpen = false.obs;
  RxBool get serviceDoorOpenRx => _serviceDoorOpen;
  bool get serviceDoorOpen => _serviceDoorOpen.value;

  Future<void> sendTestSignal() async {
    await Get.find<GpioController>().sendSerialMessage(
      SerialMessage(device: 0x01, command: 0x64),
    );
  }
}
