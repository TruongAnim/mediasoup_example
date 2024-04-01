import 'package:get/get.dart';
import 'package:mediasoup_update/core/mediasoup/calling_controller.dart';
import 'package:mediasoup_update/features/me/me_controller.dart';
import 'package:mediasoup_update/features/peers/peer_controller.dart';
import 'package:mediasoup_update/features/producers/producer_controller.dart';
import 'package:mediasoup_update/features/room/room_controller.dart';

class RoomBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<CallingController>(CallingController());
  }
}
