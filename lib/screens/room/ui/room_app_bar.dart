import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mediasoup_update/core/mediasoup/call_info_controller.dart';
import 'package:mediasoup_update/core/mediasoup/calling_controller.dart';

class RoomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool display;
  const RoomAppBar({Key? key, required this.display}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: display ? 1.0 : 0.0,
          child: AppBar(
            elevation: 5,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            title: Builder(
              builder: (context) {
                String roomId = Get.find<CallInfoController>().roomId;
                return Text(
                  'Room id: $roomId',
                  style: const TextStyle(
                    color: Colors.black,
                  ),
                );
              },
            ),
            actions: [
              IconButton(
                onPressed: () {
                  String url = Get.find<CallInfoController>().getRoomUrl();
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied: $url'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.copy,
                  color: Colors.black,
                ),
              ),
            ],
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black,
              ),
              onPressed: () {
                Get.find<CallingController>().close();
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
