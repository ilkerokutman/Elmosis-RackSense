import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/core/routes/pages.dart';
import 'package:rack_sense/app/core/routes/routes.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      getPages: getPages,
      initialRoute: Routes.dashboard,
    );
  }
}
