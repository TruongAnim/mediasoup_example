import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide navigator;
import 'package:get_it/get_it.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';
import 'package:mediasoup_update/features/peers/enitity/peer.dart';
import 'package:mediasoup_update/features/signaling/room_client_repo.dart';
import 'package:mediasoup_update/helper.dart';
import 'package:mediasoup_update/utils.dart';
import 'package:random_string/random_string.dart';

class CallingController extends GetxController {
  // Name
  RxString displayName = RxString('');
  RxString id = RxString('');
  RxBool shareInProgress = RxBool(false);
  RxBool webcamInProgress = RxBool(false);

  // Device
  final RTCVideoRenderer renderer = RTCVideoRenderer();
  final RxList<MediaDeviceInfo> audioInputs = RxList();
  final RxList<MediaDeviceInfo> audioOutputs = RxList();
  final RxList<MediaDeviceInfo> videoInputs = RxList();
  final Rxn<MediaDeviceInfo> selectedAudioInput = Rxn<MediaDeviceInfo>();
  final Rxn<MediaDeviceInfo> selectedAudioOutput = Rxn<MediaDeviceInfo>();
  final Rxn<MediaDeviceInfo> selectedVideoInput = Rxn<MediaDeviceInfo>();

  // Peer
  RxString selectedOutputId = RxString('');
  RxMap<String, Peer> peers = RxMap<String, Peer>({});

  // Producer
  Rxn<Producer> mic = Rxn();
  Rxn<Producer> webcam = Rxn();
  Rxn<Producer> screen = Rxn();

  // Room
  RxnString activeSpeakerId = RxnString();
  RxnString state = RxnString();
  RxString url = RxString('');

  @override
  void onInit() {
    super.onInit();
    _initRoom();
    _initName();
    _initRenderers();

    _initMediaDevice();
  }

  @override
  void onClose() {
    super.onClose();
    GetIt.I.unregister<RoomClientRepo>();
  }

  // Name
  void _initName() {
    id.value = randomAlpha(8);
    displayName.value = nouns[Random.secure().nextInt(2500)];
  }

  void setWebcamInProgress({required bool progress}) {
    webcamInProgress.value = progress;
  }

  // Device
  _initRenderers() async {
    await renderer.initialize();
  }

  _initMediaDevice() async {
    try {
      final List<MediaDeviceInfo> devices = await navigator.mediaDevices.enumerateDevices();

      final List<MediaDeviceInfo> audioInputs = [];
      final List<MediaDeviceInfo> audioOutputs = [];
      final List<MediaDeviceInfo> videoInputs = [];

      for (var device in devices) {
        switch (device.kind) {
          case 'audioinput':
            audioInputs.add(device);
            break;
          case 'audiooutput':
            audioOutputs.add(device);
            break;
          case 'videoinput':
            videoInputs.add(device);
            break;
          default:
            break;
        }
      }
      MediaDeviceInfo? selectedAudioInput;
      MediaDeviceInfo? selectedAudioOutput;
      MediaDeviceInfo? selectedVideoInput;
      if (audioInputs.isNotEmpty) {
        selectedAudioInput = audioInputs.first;
      }
      if (audioOutputs.isNotEmpty) {
        selectedAudioOutput = audioOutputs.first;
      }
      if (videoInputs.isNotEmpty) {
        selectedVideoInput = videoInputs.first;
      }

      this.audioInputs.value = audioInputs;
      this.audioOutputs.value = audioOutputs;
      this.videoInputs.value = videoInputs;
      this.selectedAudioInput.value = selectedAudioInput;
      this.selectedAudioOutput.value = selectedAudioOutput;
      this.selectedVideoInput.value = selectedVideoInput;
    } catch (e) {
      appPrint(e);
    }
  }

  // Peer
  void addPeer(Map<String, dynamic> newPeer) {
    final Peer temp = Peer.fromMap(newPeer);
    peers[temp.id] = temp;
    peers.refresh();
  }

  void removePeer(String peerId) {
    peers.remove(peerId);
  }

  void addConsummer({required Consumer consumer, String? peerId}) async {
    if (kIsWeb) {
      if (peers[peerId]!.renderer == null) {
        peers[peerId!] = peers[peerId]!.copyWith(renderer: RTCVideoRenderer());
        await peers[peerId]!.renderer!.initialize();
        // newPeers[event.peerId]!.renderer!.audioOutput = selectedOutputId;
      }

      if (consumer.kind == 'video') {
        peers[peerId!] = peers[peerId]!.copyWith(video: consumer);
        peers[peerId]!.renderer!.srcObject = peers[peerId]!.video!.stream;
      }

      if (consumer.kind == 'audio') {
        peers[peerId!] = peers[peerId]!.copyWith(audio: consumer);
        if (peers[peerId]!.video == null) {
          peers[peerId]!.renderer!.srcObject = peers[peerId]!.audio!.stream;
        }
      }
    } else {
      if (consumer.kind == 'video') {
        peers[peerId!] = peers[peerId]!.copyWith(
          renderer: RTCVideoRenderer(),
          video: consumer,
        );
        await peers[peerId]!.renderer!.initialize();
        // newPeers[event.peerId]!.renderer!.audioOutput = selectedOutputId;
        peers[peerId]!.renderer!.srcObject = peers[peerId]!.video!.stream;
      } else {
        peers[peerId!] = peers[peerId]!.copyWith(
          audio: consumer,
        );
      }
    }
    peers.refresh();
  }

  void removeConsummer(String consumerId) async {
    final Peer? peer = peers.values.firstWhereOrNull((p) => p.consumers.contains(consumerId));

    if (peer != null) {
      if (kIsWeb) {
        if (peer.audio?.id == consumerId) {
          final consumer = peer.audio;
          if (peer.video == null) {
            final renderer = peers[peer.id]?.renderer!;
            peers[peer.id] = peers[peer.id]!.removeAudioAndRenderer();
            peers.value = peers;
            await Future.delayed(const Duration(microseconds: 300));
            await renderer?.dispose();
          } else {
            peers[peer.id] = peers[peer.id]!.removeAudio();
            peers.value = peers;
          }
          await consumer?.close();
        } else if (peer.video?.id == consumerId) {
          final consumer = peer.video;
          if (peer.audio != null) {
            peers[peer.id]!.renderer!.srcObject = peers[peer.id]!.audio!.stream;
            peers[peer.id] = peers[peer.id]!.removeVideo();
            peers.value = peers;
          } else {
            final renderer = peers[peer.id]!.renderer!;
            peers[peer.id] = peers[peer.id]!.removeVideoAndRenderer();
            peers.value = peers;
            await renderer.dispose();
          }
          await consumer?.close();
        }
      } else {
        if (peer.audio?.id == consumerId) {
          final consumer = peer.audio;
          peers[peer.id] = peers[peer.id]!.removeAudio();
          peers.value = peers;
          await consumer?.close();
        } else if (peer.video?.id == consumerId) {
          final consumer = peer.video;
          final renderer = peer.renderer;
          peers[peer.id] = peers[peer.id]!.removeVideoAndRenderer();
          peers.value = peers;
          consumer
              ?.close()
              .then((_) => Future.delayed(const Duration(microseconds: 300)))
              .then((_) async => await renderer?.dispose());
        }
      }
    }
    peers.refresh();
  }

  void pauseConsummer(String consumerId) {
    final Peer? peer = peers.values.firstWhereOrNull((p) => p.consumers.contains(consumerId));

    if (peer != null) {
      peers[peer.id] = peers[peer.id]!.copyWith(
        audio: peer.audio!.pauseCopy(),
      );

      peers.value = peers;
    }
    peers.refresh();
  }

  void resumeConsummer(String consumerId) {
    final Peer? peer = peers.values.firstWhereOrNull((p) => p.consumers.contains(consumerId));

    if (peer != null) {
      peers[peer.id] = peers[peer.id]!.copyWith(
        audio: peer.audio!.resumeCopy(),
      );

      peers.value = peers;
    }
    peers.refresh();
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

  // Room
  void _initRoom() {
    final arg = Get.arguments;
    final id = arg != null && arg.isNotEmpty ? arg : randomNumeric(6).toLowerCase();
    url.value = 'https://v3demo.mediasoup.org/?roomId=$id';
  }

  void initRepo() {
    String url = this.url.value;

    Uri? uri = Uri.parse(url);

    final roomClientRepo = RoomClientRepo(
      peerId: id.value,
      displayName: displayName.value,
      url: url.isEmpty ? 'wss://${uri.host}:4443' : 'wss://v3demo.mediasoup.org:4443',
      roomId: uri.queryParameters['roomId'] ?? uri.queryParameters['roomid'] ?? randomAlpha(8).toLowerCase(),
    )..join();
    GetIt.I.registerSingleton<RoomClientRepo>(roomClientRepo);
  }

  void setActiveSpeakerId(String? speakerId) {
    activeSpeakerId.value = speakerId;
  }
}
