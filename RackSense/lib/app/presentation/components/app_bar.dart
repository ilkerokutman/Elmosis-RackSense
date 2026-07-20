import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/core/routes/routes.dart';
import 'package:rack_sense/app/core/utils/common_utils.dart';

class AppBarWidget extends StatelessWidget {
  const AppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actions: [
        IconButton(
          onPressed: () {
            Get.toNamed(Routes.sync);
          },
          icon: Icon(Icons.sync),
        ),
        IconButton(
          onPressed: () {
            Get.toNamed(Routes.settings);
          },
          icon: Icon(Icons.settings),
        ),
        IconButton(
          onPressed: () async => await CU.exitAppDialog(context),
          icon: Icon(Icons.close),
        ),
      ],
    );
  }
}
