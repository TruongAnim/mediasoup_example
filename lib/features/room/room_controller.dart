import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:mediasoup_update/features/me/me_controller.dart';
import 'package:mediasoup_update/features/signaling/room_client_repo.dart';
import 'package:random_string/random_string.dart';

class RoomController extends GetxController {
  RxnString activeSpeakerId = RxnString();
  RxnString state = RxnString();
  RxString url = RxString('');

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    final id = arg != null && arg.isNotEmpty ? arg : randomNumeric(6).toLowerCase();
    url.value = 'https://v3demo.mediasoup.org/?roomId=$id';
    _initRepo();
  }

  @override
  void onClose() {
    super.onClose();
    GetIt.I.unregister<RoomClientRepo>();
  }

  void _initRepo() {
    String displayName = Get.find<MeController>().displayName.value;
    String id = Get.find<MeController>().id.value;
    String url = this.url.value;

    Uri? uri = Uri.parse(url);

    final roomClientRepo = RoomClientRepo(
      peerId: id,
      displayName: displayName,
      url: url.isEmpty ? 'wss://${uri.host}:4443' : 'wss://v3demo.mediasoup.org:4443',
      roomId: uri.queryParameters['roomId'] ?? uri.queryParameters['roomid'] ?? randomAlpha(8).toLowerCase(),
    )..join();
    GetIt.I.registerSingleton<RoomClientRepo>(roomClientRepo);
  }

  void setActiveSpeakerId(String? speakerId) {
    activeSpeakerId.value = speakerId;
  }
}
