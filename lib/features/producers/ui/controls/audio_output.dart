import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mediasoup_update/features/media_devices/media_device_controller.dart';

class AudioOutput extends GetView<MediaDeviceController> {
  const AudioOutput({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<MediaDeviceInfo> audioOutputs = controller.audioOutputs;
    final MediaDeviceInfo? selectedAudioOutput = controller.selectedAudioOutput.value;

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
        return;
        // int index = audioOutputs.indexWhere((ao) => ao.deviceId == selectedAudioOutput?.deviceId);
        // if (index != -1) {
        //   context.read<MediaDevicesBloc>().add(MediaDeviceSelectAudioOutput(
        //         audioOutputs[++index % audioOutputs.length - 1],
        //       ));
        // }
      },
      child: Stack(
        children: [
          const Icon(
            Icons.speaker,
            color: Colors.black,
          ),
          Text(
            '${audioOutputs.indexWhere((ao) => ao.deviceId == selectedAudioOutput?.deviceId)}',
            style: const TextStyle(
              color: Colors.green,
            ),
          )
        ],
      ),
    );
  }
}
