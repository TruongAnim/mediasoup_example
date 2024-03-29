import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediasoup_update/features/media_devices/bloc/media_devices_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class AudioOutput extends StatelessWidget {
  const AudioOutput({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<MediaDeviceInfo> audioOutputs = context.select((MediaDevicesBloc bloc) => bloc.state.audioOutputs);
    final MediaDeviceInfo? selectedAudioOutput =
        context.select((MediaDevicesBloc bloc) => bloc.state.selectedAudioOutput);

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
