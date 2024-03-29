import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:mediasoup_update/features/media_devices/ui/media_device_selector.dart';

import '../media_device_controller.dart';

class AudioInputSelector extends GetView<MediaDeviceController> {
  const AudioInputSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final List<MediaDeviceInfo> audioInputDevices = controller.audioInputs;
        final MediaDeviceInfo? selectedAudioInput = controller.selectedAudioInput.value;
        return MediaDeviceSelector(
          selected: selectedAudioInput,
          options: audioInputDevices,
          onChanged: (MediaDeviceInfo? device) {
            controller.selectedAudioInput.value = device;
          },
        );
      },
    );
  }
}
