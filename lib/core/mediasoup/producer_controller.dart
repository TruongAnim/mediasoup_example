import 'package:get/get.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';

class ProducerController extends GetxController {
  Rxn<Producer> mic = Rxn();
  Rxn<Producer> webcam = Rxn();
  Rxn<Producer> screen = Rxn();

  @override
  void onInit() {
    super.onInit();
  }

  // producer
  void removeMic() {
    mic.value?.close();
    mic.value = null;
  }

  void removeWebcame() {
    webcam.value?.close();
    webcam.value = null;
  }

  void removeScreen() {
    screen.value?.close();
    screen.value = null;
  }

  void pauseMic() {
    mic.value?.pauseCopy();
  }

  void pauseWebcame() {
    webcam.value?.pauseCopy();
  }

  void pauseScreen() {
    screen.value?.pauseCopy();
  }

  void resumeMic() {
    mic.value?.resumeCopy();
  }

  void resumeWebcame() {
    webcam.value?.resumeCopy();
  }

  void resumeScreen() {
    screen.value?.resumeCopy();
  }

  void updateProducer(Producer newProducer) {
    switch (newProducer.source) {
      case 'mic':
        mic.value = newProducer;
      case 'webcam':
        webcam.value = newProducer;
      case 'screen':
        screen.value = newProducer;
      default:
        break;
    }
  }
}
