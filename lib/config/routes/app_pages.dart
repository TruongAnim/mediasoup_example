import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:mediasoup_update/config/routes/route_path/base_routers.dart';

mixin AppPages {
  static List<GetPage> list = [
    ...BaseRouters.listPage,
  ];
}
