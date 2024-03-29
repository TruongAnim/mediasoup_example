import 'package:get/get.dart';
import 'package:mediasoup_update/core/app_controller.dart';
import 'package:mediasoup_update/features/media_devices/media_device_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AppController>(AppController());
    Get.lazyPut<MediaDeviceController>(() => MediaDeviceController());
  }
}
