import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:mediasoup_update/features/me/me_controller.dart';
import 'package:mediasoup_update/features/media_devices/media_device_controller.dart';
import 'package:flutter/material.dart';
import 'package:mediasoup_update/features/producers/producer_controller.dart';
import 'package:mediasoup_update/features/signaling/room_client_repo.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';

class Webcam extends GetView<ProducerController> {
  const Webcam({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final RoomClientRepo roomClientRepo = GetIt.I.get<RoomClientRepo>();
        final int videoInputDevicesLength = Get.find<MediaDeviceController>().videoInputs.length;
        final bool inProgress = Get.find<MeController>().webcamInProgress.value;
        final Producer? webcam = controller.webcam.value;
        if (videoInputDevicesLength == 0) {
          return IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.videocam,
              color: Colors.grey,
              // size: screenHeight * 0.045,
            ),
          );
        }
        if (webcam == null) {
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
              if (!inProgress) {
                roomClientRepo.enableWebcam();
              }
            },
            child: const Icon(
              Icons.videocam_off,
              color: Colors.black,
              // size: screenHeight * 0.045,
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
            if (!inProgress) {
              roomClientRepo.disableWebcam();
            }
          },
          child: const Icon(
            Icons.videocam,
            color: Colors.black,
            // size: screenHeight * 0.045,
          ),
        );
      },
    );
  }
}
