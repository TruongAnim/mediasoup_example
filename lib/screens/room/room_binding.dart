import 'package:get/get.dart';
import 'package:mediasoup_update/core/mediasoup/calling_controller.dart';

class RoomBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<CallingController>(CallingController());
  }
}
