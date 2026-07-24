enum MainboardInput {
  input1(1, 5),
  input2(2, 6),
  input3(3, 12),
  input4(4, 13),
  input5(5, 19),
  input6(6, 16),
  input7(7, 26),
  input8(8, 20);

  const MainboardInput(this.number, this.gpioPin);

  final int number;
  final int gpioPin;

  String get label => 'Input $number';
}
