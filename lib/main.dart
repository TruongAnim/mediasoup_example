import 'dart:io';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:mediasoup_update/app_binding.dart';
import 'package:mediasoup_update/config/routes/app_pages.dart';
import 'package:mediasoup_update/config/routes/route_path/base_routers.dart';
import 'package:flutter/material.dart';

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = DevHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialRoute: BaseRouters.HOME,
      initialBinding: AppBinding(),
      transitionDuration: const Duration(),
      getPages: AppPages.list,
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(
        builder: (context, widget) {
          return widget!;
        },
      ),
    );
  }
}
