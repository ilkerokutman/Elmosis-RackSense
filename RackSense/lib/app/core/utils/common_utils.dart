class CU {
  static Future<void> wait(int milliseconds) async {
    return await Future.delayed(Duration(milliseconds: milliseconds));
  }

  static Future<void> microWait() async {
    return await Future.delayed(Duration(microseconds: 100));
  }
}
