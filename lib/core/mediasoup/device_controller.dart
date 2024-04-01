import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:mediasoup_update/helper.dart';

class DeviceController extends GetxController {
  List<MediaDeviceInfo> devices = [];
  final RxList<MediaDeviceInfo> audioInputs = RxList();
  final RxList<MediaDeviceInfo> audioOutputs = RxList();
  final RxList<MediaDeviceInfo> videoInputs = RxList();
  final Rxn<MediaDeviceInfo> selectedAudioInput = Rxn<MediaDeviceInfo>();
  final Rxn<MediaDeviceInfo> selectedAudioOutput = Rxn<MediaDeviceInfo>();
  final Rxn<MediaDeviceInfo> selectedVideoInput = Rxn<MediaDeviceInfo>();
  String? audioInputDeviceId;
  String? audioOutputDeviceId;
  String? videoInputDeviceId;
  @override
  void onInit() {
    super.onInit();
    _initMediaDevice();
  }

  _initMediaDevice() async {
    try {
      devices = await navigator.mediaDevices.enumerateDevices();

      final List<MediaDeviceInfo> audioInputs = [];
      final List<MediaDeviceInfo> audioOutputs = [];
      final List<MediaDeviceInfo> videoInputs = [];

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
      MediaDeviceInfo? selectedAudioInput;
      MediaDeviceInfo? selectedAudioOutput;
      MediaDeviceInfo? selectedVideoInput;
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
