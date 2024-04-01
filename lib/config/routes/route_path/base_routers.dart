// ignore_for_file: constant_identifier_names

import 'package:get/get.dart';
import 'package:mediasoup_update/screens/room/room.dart';
import 'package:mediasoup_update/screens/room/room_binding.dart';
import 'package:mediasoup_update/screens/welcome/welcome.dart';
import 'package:mediasoup_update/screens/welcome/welcome_binding.dart';

mixin BaseRouters {
  static const String HOME = '/home';
  static const String ROOM = '/room';

  static List<GetPage> listPage = [
    GetPage(
      name: HOME,
      page: () => const Welcome(),
      binding: WelcomeBinding(),
    ),
    GetPage(
      name: ROOM,
      page: () => const Room(),
      binding: RoomBinding(),
    ),
  ];
}
