import 'package:dart_periphery/dart_periphery.dart';

enum PinType { digitalOutput, digitalInput, analogInput, buttonInput }

class PinState {
  int device;
  int number;
  PinType type;
  bool status;
  double value;
  String? description;
  GPIO? pin;
  PinState({
    required this.device,
    required this.number,
    required this.type,
    this.status = false,
    this.value = 0.0,
    this.description,
    this.pin,
  });
}
