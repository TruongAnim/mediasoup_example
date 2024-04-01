import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:mediasoup_update/core/mediasoup/device_controller.dart';
import 'package:mediasoup_update/features/media_devices/ui/media_device_selector.dart';

class VideoInputSelector extends GetView<DeviceController> {
  const VideoInputSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final List<MediaDeviceInfo> videoInputDevices = controller.videoInputs;
        final MediaDeviceInfo? selectedVideoInput = controller.selectedVideoInput.value;
        return MediaDeviceSelector(
          selected: selectedVideoInput,
          options: videoInputDevices,
          onChanged: (MediaDeviceInfo? device) {
            controller.selectedVideoInput.value = device;
          },
        );
      },
    );
  }
}
