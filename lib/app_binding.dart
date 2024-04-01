import 'package:get/get.dart';
import 'package:mediasoup_update/core/app_controller.dart';
import 'package:mediasoup_update/core/mediasoup/calling_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AppController>(AppController());
    Get.lazyPut<CallingController>(() => CallingController());
  }
}
