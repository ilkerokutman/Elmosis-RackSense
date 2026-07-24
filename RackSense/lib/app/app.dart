import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/core/routes/pages.dart';
import 'package:rack_sense/app/core/routes/routes.dart';
import 'package:rack_sense/app/core/themes/theme.dart';
import 'package:rack_sense/app/core/utils/theme_utils.dart';
import 'package:rack_sense/app/data/controllers/settings_controller.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = ThemeUtils.createTextTheme(
      context,
      "Poppins",
      "Montserrat",
    );

    MaterialTheme theme = MaterialTheme(textTheme);

    return GetX<SettingsController>(
      builder: (settingsController) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        getPages: getPages,
        initialRoute: Routes.dashboard,
        theme: theme.light(),
        darkTheme: theme.dark(),
        highContrastTheme: theme.lightHighContrast(),
        highContrastDarkTheme: theme.darkHighContrast(),
        themeMode: settingsController.settings.isDarkMode
            ? ThemeMode.dark
            : ThemeMode.light,
      ),
    );
  }
}
