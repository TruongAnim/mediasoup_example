import 'package:get/get.dart';
import 'package:mediasoup_update/core/mediasoup/device_controller.dart';

class WelcomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<DeviceController>(DeviceController());
  }
}
