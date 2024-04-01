import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mediasoup_update/core/mediasoup/calling_controller.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';
import 'package:mediasoup_update/core/mediasoup/device_controller.dart';
import 'package:mediasoup_update/core/mediasoup/producer_controller.dart';

class Microphone extends GetView<CallingController> {
  const Microphone({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final Producer? microphone = Get.find<ProducerController>().mic.value;
        final int audioInputDevicesLength = Get.find<DeviceController>().audioInputs.length;
        if (audioInputDevicesLength == 0) {
          return IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.mic_off,
              color: Colors.grey,
            ),
          );
        }
        return ElevatedButton(
          style: ButtonStyle(
            shape: MaterialStateProperty.all(const CircleBorder()),
            padding: MaterialStateProperty.all(const EdgeInsets.all(8)),
            backgroundColor: MaterialStateProperty.all(Colors.white),
            overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
              if (states.contains(MaterialState.pressed)) return Colors.grey;
              return null;
            }),
            shadowColor: MaterialStateProperty.resolveWith<Color?>((states) {
              if (states.contains(MaterialState.pressed)) return Colors.grey;
              return null;
            }),
          ),
          onPressed: () {
            if (microphone?.paused == true) {
              controller.unmuteMic();
            } else {
              controller.muteMic();
            }
          },
          child: Icon(
            microphone?.paused == true ? Icons.mic_off : Icons.mic,
            color: microphone == null ? Colors.grey : Colors.black,
          ),
        );
      },
    );
  }
}
