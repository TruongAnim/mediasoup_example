import 'package:get/get.dart';

import 'models/caller_info.dart';

class CallInfoController extends GetxController {
  CallerInfo me = CallerInfo();
  CallerInfo other = CallerInfo();
  String roomId = '';
  String peerId = '';
  String socket = '';
  String roomUrl = '';

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is Map<String, dynamic>) {
      me.id = arg['id'];
      me.name = arg['name'];
      other.id = arg['otherId'];
      other.name = arg['otherName'];
      roomId = arg['roomId'];
      peerId = arg['peerId'];
      socket = arg['socket'];
      roomUrl = arg['roomUrl'];
    }
  }

  String getRoomUrl() {
    return '$roomUrl?roomId=$roomId';
  }
}
