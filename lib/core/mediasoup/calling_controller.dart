// ignore_for_file: empty_catches

import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:get/get.dart' hide navigator;
import 'package:mediasoup_update/features/peers/enitity/peer.dart';
import 'package:mediasoup_update/features/signaling/web_socket.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';
import 'package:mediasoup_update/helper.dart';
import 'package:mediasoup_update/utils.dart';
import 'package:random_string/random_string.dart';

class CallingController extends GetxController {
  String roomId = '';
  String peerId = '';
  String url = '';
  String displayName = '';

  final bool _closed = false;

  WebSocket? _webSocket;
  Device? _mediasoupDevice;
  Transport? _sendTransport;
  Transport? _recvTransport;
  bool _produce = false;
  final bool _consume = true;
  StreamSubscription<MediaDeviceInfo?>? _audioInputSubscription;
  StreamSubscription<MediaDeviceInfo?>? _videoInputSubscription;
  String? audioInputDeviceId;
  String? audioOutputDeviceId;
  String? videoInputDeviceId;

  CallingController();

  // Name
  RxString rxDisplayName = RxString('');
  RxString rxId = RxString('');
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
  RxString rxUrl = RxString('');

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
  }

  // Name
  void _initName() {
    rxId.value = randomAlpha(8);
    rxDisplayName.value = nouns[Random.secure().nextInt(2500)];
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
            await Future.delayed(const Duration(microseconds: 300));
            await renderer?.dispose();
          } else {
            peers[peer.id] = peers[peer.id]!.removeAudio();
          }
          await consumer?.close();
        } else if (peer.video?.id == consumerId) {
          final consumer = peer.video;
          if (peer.audio != null) {
            peers[peer.id]!.renderer!.srcObject = peers[peer.id]!.audio!.stream;
            peers[peer.id] = peers[peer.id]!.removeVideo();
          } else {
            final renderer = peers[peer.id]!.renderer!;
            peers[peer.id] = peers[peer.id]!.removeVideoAndRenderer();
            await renderer.dispose();
          }
          await consumer?.close();
        }
      } else {
        if (peer.audio?.id == consumerId) {
          final consumer = peer.audio;
          peers[peer.id] = peers[peer.id]!.removeAudio();
          await consumer?.close();
        } else if (peer.video?.id == consumerId) {
          final consumer = peer.video;
          final renderer = peer.renderer;
          peers[peer.id] = peers[peer.id]!.removeVideoAndRenderer();
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
    }
    peers.refresh();
  }

  void resumeConsummer(String consumerId) {
    final Peer? peer = peers.values.firstWhereOrNull((p) => p.consumers.contains(consumerId));

    if (peer != null) {
      peers[peer.id] = peers[peer.id]!.copyWith(
        audio: peer.audio!.resumeCopy(),
      );
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
    rxUrl.value = 'https://v3demo.mediasoup.org/?roomId=$id';
  }

  void initRepo() {
    url = rxUrl.value;

    Uri? uri = Uri.parse(url);

    peerId = rxId.value;
    displayName = rxDisplayName.value;
    url = url.isEmpty ? 'wss://${uri.host}:4443' : 'wss://v3demo.mediasoup.org:4443';
    roomId = uri.queryParameters['roomId'] ?? uri.queryParameters['roomid'] ?? randomAlpha(8).toLowerCase();

    join();
    _audioInputSubscription = selectedAudioInput.stream.listen((MediaDeviceInfo? audioInput) async {
      if (audioInput != null && audioInput.deviceId != audioInputDeviceId) {
        await disableMic();
        enableMic();
      }
    });
    _videoInputSubscription = selectedAudioInput.stream.listen((MediaDeviceInfo? videoInput) async {
      if (videoInput != null && videoInput.deviceId != videoInputDeviceId) {
        await disableWebcam();
        enableWebcam();
      }
    });
  }

  void setActiveSpeakerId(String? speakerId) {
    activeSpeakerId.value = speakerId;
  }

  void close() {
    if (_closed) {
      return;
    }

    _webSocket?.close();
    _sendTransport?.close();
    _recvTransport?.close();
    _audioInputSubscription?.cancel();
    _videoInputSubscription?.cancel();
  }

  Future<void> disableMic() async {
    if (mic.value == null) {
      return;
    }
    String micId = mic.value!.id;

    removeMic();

    try {
      await _webSocket!.socket.request('closeProducer', {
        'producerId': micId,
      });
    } catch (error) {}
  }

  Future<void> disableWebcam() async {
    if (webcam.value == null) {
      return;
    }
    setWebcamInProgress(progress: true);
    String webcamId = webcam.value!.id;

    removeWebcame();

    try {
      await _webSocket!.socket.request('closeProducer', {
        'producerId': webcamId,
      });
    } finally {
      setWebcamInProgress(progress: false);
    }
  }

  Future<void> muteMic() async {
    pauseMic();

    try {
      await _webSocket!.socket.request('pauseProducer', {
        'producerId': mic.value!.id,
      });
    } catch (error) {}
  }

  Future<void> unmuteMic() async {
    resumeMic();

    try {
      await _webSocket!.socket.request('resumeProducer', {
        'producerId': mic.value!.id,
      });
    } catch (error) {}
  }

  void _producerCallback(Producer producer) {
    if (producer.source == 'webcam') {
      setWebcamInProgress(progress: false);
    }
    producer.on('trackended', () {
      disableMic().catchError((data) {});
    });
    updateProducer(producer);
  }

  void _consumerCallback(Consumer consumer, [dynamic accept]) {
    ScalabilityMode scalabilityMode = ScalabilityMode.parse(consumer.rtpParameters.encodings.first.scalabilityMode);

    accept({});

    addConsummer(peerId: consumer.peerId, consumer: consumer);
  }

  Future<MediaStream> createAudioStream() async {
    audioInputDeviceId = selectedAudioInput.value?.deviceId;
    Map<String, dynamic> mediaConstraints = {
      'audio': {
        'optional': [
          {
            'sourceId': audioInputDeviceId,
          },
        ],
      },
    };

    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    return stream;
  }

  Future<MediaStream> createVideoStream() async {
    videoInputDeviceId = selectedVideoInput.value?.deviceId;
    Map<String, dynamic> mediaConstraints = <String, dynamic>{
      'audio': false,
      'video': {
        'mandatory': {
          'minWidth': '1280', // Provide your own width, height and frame rate here
          'minHeight': '720',
          'minFrameRate': '30',
        },
        'optional': [
          {
            'sourceId': videoInputDeviceId,
          },
        ],
      },
    };

    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    return stream;
  }

  void enableWebcam() async {
    if (webcamInProgress.isTrue) {
      return;
    }
    setWebcamInProgress(progress: true);
    if (_mediasoupDevice!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeVideo) == false) {
      return;
    }
    MediaStream? videoStream;
    MediaStreamTrack? track;
    try {
      // NOTE: prefer using h264
      const videoVPVersion = kIsWeb ? 9 : 8;
      RtpCodecCapability? codec = _mediasoupDevice!.rtpCapabilities.codecs.firstWhere(
          (RtpCodecCapability c) => c.mimeType.toLowerCase() == 'video/vp$videoVPVersion',
          orElse: () => throw 'desired vp$videoVPVersion codec+configuration is not supported');
      videoStream = await createVideoStream();
      track = videoStream.getVideoTracks().first;
      setWebcamInProgress(progress: true);
      _sendTransport!.produce(
        track: track,
        codecOptions: ProducerCodecOptions(
          videoGoogleStartBitrate: 1000,
        ),
        encodings: kIsWeb
            ? [
                RtpEncodingParameters(scalabilityMode: 'S3T3_KEY', scaleResolutionDownBy: 1.0),
              ]
            : [],
        stream: videoStream,
        appData: {
          'source': 'webcam',
        },
        source: 'webcam',
        codec: codec,
      );
    } catch (error) {
      if (videoStream != null) {
        await videoStream.dispose();
      }
    }
  }

  void enableMic() async {
    if (_mediasoupDevice!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeAudio) == false) {
      return;
    }

    MediaStream? audioStream;
    MediaStreamTrack? track;
    try {
      audioStream = await createAudioStream();
      track = audioStream.getAudioTracks().first;
      _sendTransport!.produce(
        track: track,
        codecOptions: ProducerCodecOptions(opusStereo: 1, opusDtx: 1),
        stream: audioStream,
        appData: {
          'source': 'mic',
        },
        source: 'mic',
      );
    } catch (error) {
      if (audioStream != null) {
        await audioStream.dispose();
      }
    }
  }

  Future<void> _joinRoom() async {
    try {
      _mediasoupDevice = Device();

      dynamic routerRtpCapabilities = await _webSocket!.socket.request('getRouterRtpCapabilities', {});

      appPrint(routerRtpCapabilities);

      final rtpCapabilities = RtpCapabilities.fromMap(routerRtpCapabilities);
      rtpCapabilities.headerExtensions.removeWhere((he) => he.uri == 'urn:3gpp:video-orientation');
      await _mediasoupDevice!.load(routerRtpCapabilities: rtpCapabilities);

      if (_mediasoupDevice!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeAudio) == true ||
          _mediasoupDevice!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeVideo) == true) {
        _produce = true;
      }

      if (_produce) {
        Map transportInfo = await _webSocket!.socket.request('createWebRtcTransport', {
          'forceTcp': false,
          'producing': true,
          'consuming': false,
          'sctpCapabilities': _mediasoupDevice!.sctpCapabilities.toMap(),
        });

        _sendTransport = _mediasoupDevice!.createSendTransportFromMap(
          transportInfo,
          producerCallback: _producerCallback,
        );

        _sendTransport!.on('connect', (Map data) {
          _webSocket!.socket
              .request('connectWebRtcTransport', {
                'transportId': _sendTransport!.id,
                'dtlsParameters': data['dtlsParameters'].toMap(),
              })
              .then(data['callback'])
              .catchError(data['errback']);
        });

        _sendTransport!.on('produce', (Map data) async {
          try {
            Map response = await _webSocket!.socket.request(
              'produce',
              {
                'transportId': _sendTransport!.id,
                'kind': data['kind'],
                'rtpParameters': data['rtpParameters'].toMap(),
                if (data['appData'] != null) 'appData': Map<String, dynamic>.from(data['appData'])
              },
            );

            data['callback'](response['id']);
          } catch (error) {
            data['errback'](error);
          }
        });

        _sendTransport!.on('producedata', (data) async {
          try {
            Map response = await _webSocket!.socket.request('produceData', {
              'transportId': _sendTransport!.id,
              'sctpStreamParameters': data['sctpStreamParameters'].toMap(),
              'label': data['label'],
              'protocol': data['protocol'],
              'appData': data['appData'],
            });

            data['callback'](response['id']);
          } catch (error) {
            data['errback'](error);
          }
        });
      }

      if (_consume) {
        Map transportInfo = await _webSocket!.socket.request(
          'createWebRtcTransport',
          {
            'forceTcp': false,
            'producing': false,
            'consuming': true,
            'sctpCapabilities': _mediasoupDevice!.sctpCapabilities.toMap(),
          },
        );

        _recvTransport = _mediasoupDevice!.createRecvTransportFromMap(
          transportInfo,
          consumerCallback: _consumerCallback,
        );

        _recvTransport!.on(
          'connect',
          (data) {
            _webSocket!.socket
                .request(
                  'connectWebRtcTransport',
                  {
                    'transportId': _recvTransport!.id,
                    'dtlsParameters': data['dtlsParameters'].toMap(),
                  },
                )
                .then(data['callback'])
                .catchError(data['errback']);
          },
        );
      }

      Map response = await _webSocket!.socket.request('join', {
        'displayName': displayName,
        'device': {
          'name': "Flutter",
          'flag': 'flutter',
          'version': '0.8.0',
        },
        'rtpCapabilities': _mediasoupDevice!.rtpCapabilities.toMap(),
        'sctpCapabilities': _mediasoupDevice!.sctpCapabilities.toMap(),
      });

      response['peers'].forEach((value) {
        addPeer(value);
      });

      if (_produce) {
        enableMic();
        enableWebcam();

        _sendTransport!.on('connectionstatechange', (connectionState) {
          if (connectionState == 'connected') {
            // enableChatDataProducer();
            // enableBotDataProducer();
          }
        });
      }
    } catch (error) {
      appPrint(error);
      close();
    }
  }

  void join() {
    print('truong ${peerId}');
    print('truong ${roomId}');
    print('truong ${url}');
    _webSocket = WebSocket(
      peerId: peerId,
      roomId: roomId,
      url: url,
    );

    _webSocket!.onOpen = _joinRoom;
    _webSocket!.onFail = () {
      appPrint('WebSocket connection failed');
    };
    _webSocket!.onDisconnected = () {
      if (_sendTransport != null) {
        _sendTransport!.close();
        _sendTransport = null;
      }
      if (_recvTransport != null) {
        _recvTransport!.close();
        _recvTransport = null;
      }
    };
    _webSocket!.onClose = () {
      if (_closed) return;

      close();
    };

    _webSocket!.onRequest = (request, accept, reject) async {
      switch (request['method']) {
        case 'newConsumer':
          {
            if (!_consume) {
              reject(403, 'I do not want to consume');
              break;
            }
            try {
              _recvTransport!.consume(
                id: request['data']['id'],
                producerId: request['data']['producerId'],
                kind: RTCRtpMediaTypeExtension.fromString(request['data']['kind']),
                rtpParameters: RtpParameters.fromMap(request['data']['rtpParameters']),
                appData: Map<String, dynamic>.from(request['data']['appData']),
                peerId: request['data']['peerId'],
                accept: accept,
              );
            } catch (error) {
              appPrint('newConsumer request failed: $error');
              rethrow;
            }
            break;
          }
        default:
          break;
      }
    };

    _webSocket!.onNotification = (notification) async {
      switch (notification['method']) {
        case 'producerScore':
          {
            break;
          }
        case 'consumerClosed':
          {
            String consumerId = notification['data']['consumerId'];
            removeConsummer(consumerId);

            break;
          }
        case 'consumerPaused':
          {
            String consumerId = notification['data']['consumerId'];
            pauseConsummer(consumerId);
            break;
          }

        case 'consumerResumed':
          {
            String consumerId = notification['data']['consumerId'];
            resumeConsummer(consumerId);
            break;
          }

        case 'newPeer':
          {
            final Map<String, dynamic> newPeer = Map<String, dynamic>.from(notification['data']);
            addPeer(newPeer);
            break;
          }

        case 'peerClosed':
          {
            String peerId = notification['data']['peerId'];
            removePeer(peerId);
            break;
          }

        default:
          break;
      }
    };
  }
}
