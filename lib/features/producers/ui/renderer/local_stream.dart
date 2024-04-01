import 'package:get/get.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';
import 'package:mediasoup_update/core/mediasoup/calling_controller.dart';
import 'package:mediasoup_update/features/media_devices/media_device_controller.dart';
import 'package:mediasoup_update/features/producers/producer_controller.dart';
import 'package:mediasoup_update/features/producers/ui/renderer/dragger.dart';
import 'package:flutter/material.dart';

class LocalStream extends GetView<CallingController> {
  const LocalStream({Key? key}) : super(key: key);
  final double streamContainerSize = 180;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final MediaDeviceInfo? selectedVideoInput = controller.selectedVideoInput.value;
        final Producer? webcam = controller.webcam.value;
        if (controller.renderer.srcObject != webcam?.stream) {
          controller.renderer.srcObject = webcam?.stream;
        }
        if (controller.renderer.srcObject != null && controller.renderer.renderVideo) {
          return Dragger(
            key: const ValueKey('Dragger'),
            child2: Container(
              key: const ValueKey('RenderMe_View'),
              width: streamContainerSize - 4,
              height: streamContainerSize - 4,
              margin: const EdgeInsets.all(2),
              child: ClipOval(
                child: RTCVideoView(
                  controller.renderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  mirror: selectedVideoInput != null && selectedVideoInput.label.contains('back') ? false : true,
                  // mirror: true,
                ),
              ),
            ),
            child: Container(
              key: const ValueKey('RenderMe_Border'),
              width: streamContainerSize,
              height: streamContainerSize,
              // margin: const EdgeInsets.only(left: 5, bottom: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red,
                  width: 2.0,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
