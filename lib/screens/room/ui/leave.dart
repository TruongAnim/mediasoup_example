import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:mediasoup_update/core/mediasoup/calling_controller.dart';

class Leave extends StatelessWidget {
  const Leave({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        shape: MaterialStateProperty.all(const CircleBorder()),
        padding: MaterialStateProperty.all(const EdgeInsets.all(8)),
        backgroundColor: MaterialStateProperty.all(Colors.red), // <-- Button color
        overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.pressed)) return Colors.red.shade900;
          return null; // <-- Splash color
        }),
        shadowColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.pressed)) return Colors.red;
          return null; // <-- Splash color
        }),
      ),
      onPressed: () {
        Get.find<CallingController>().close();
        Navigator.pop(context);
      },
      child: const Icon(
        Icons.call_end,
        color: Colors.white,
        // size: screenHeight * 0.045,
      ),
    );
  }
}
