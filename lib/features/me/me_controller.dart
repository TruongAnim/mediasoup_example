import 'dart:math';

import 'package:get/get.dart';
import 'package:mediasoup_update/utils.dart';
import 'package:random_string/random_string.dart';

class MeController extends GetxController {
  RxString displayName = RxString('');
  RxString id = RxString('');
  RxBool shareInProgress = RxBool(false);
  RxBool webcamInProgress = RxBool(false);

  @override
  void onInit() {
    super.onInit();
    id.value = randomAlpha(8);
    displayName.value = nouns[Random.secure().nextInt(2500)];
  }

  void setWebcamInProgress({required bool progress}) {
    webcamInProgress.value = progress;
  }
}
