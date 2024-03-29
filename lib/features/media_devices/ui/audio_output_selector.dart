import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:mediasoup_update/features/media_devices/ui/media_device_selector.dart';

import '../media_device_controller.dart';

class AudioOutputSelector extends GetView<MediaDeviceController> {
  const AudioOutputSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final List<MediaDeviceInfo> audioOutputDevices = controller.audioOutputs;
        final MediaDeviceInfo? selectedAudioOutput = controller.selectedAudioOutput.value;
        return MediaDeviceSelector(
          selected: selectedAudioOutput,
          options: audioOutputDevices,
          onChanged: (MediaDeviceInfo? device) {
            controller.selectedAudioOutput.value = device;
          },
        );
      },
    );
  }
}
