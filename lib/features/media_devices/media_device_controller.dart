import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:mediasoup_update/helper.dart';

class MediaDeviceController extends GetxController {
  final RTCVideoRenderer renderer = RTCVideoRenderer();
  final RxList<MediaDeviceInfo> audioInputs = RxList();
  final RxList<MediaDeviceInfo> audioOutputs = RxList();
  final RxList<MediaDeviceInfo> videoInputs = RxList();
  final Rxn<MediaDeviceInfo> selectedAudioInput = Rxn<MediaDeviceInfo>();
  final Rxn<MediaDeviceInfo> selectedAudioOutput = Rxn<MediaDeviceInfo>();
  final Rxn<MediaDeviceInfo> selectedVideoInput = Rxn<MediaDeviceInfo>();

  @override
  void onInit() {
    super.onInit();
    _initRenderers();
    _initMediaDevice();
  }

  _initRenderers() async {
    await renderer.initialize();
  }

  _initMediaDevice() async {
    try {
      final List<webrtc.MediaDeviceInfo> devices = await webrtc.navigator.mediaDevices.enumerateDevices();

      final List<webrtc.MediaDeviceInfo> audioInputs = [];
      final List<webrtc.MediaDeviceInfo> audioOutputs = [];
      final List<webrtc.MediaDeviceInfo> videoInputs = [];

      for (var device in devices) {
        switch (device.kind) {
          case 'audioinput':
            audioInputs.add(device);
            break;
          case 'audiooutput':
            audioOutputs.add(device);
            break;
          case 'videoinput':
            videoInputs.add(device);
            break;
          default:
            break;
        }
      }
      webrtc.MediaDeviceInfo? selectedAudioInput;
      webrtc.MediaDeviceInfo? selectedAudioOutput;
      webrtc.MediaDeviceInfo? selectedVideoInput;
      if (audioInputs.isNotEmpty) {
        selectedAudioInput = audioInputs.first;
      }
      if (audioOutputs.isNotEmpty) {
        selectedAudioOutput = audioOutputs.first;
      }
      if (videoInputs.isNotEmpty) {
        selectedVideoInput = videoInputs.first;
      }

      this.audioInputs.value = audioInputs;
      this.audioOutputs.value = audioOutputs;
      this.videoInputs.value = videoInputs;
      this.selectedAudioInput.value = selectedAudioInput;
      this.selectedAudioOutput.value = selectedAudioOutput;
      this.selectedVideoInput.value = selectedVideoInput;
    } catch (e) {
      appPrint(e);
    }
  }
}
