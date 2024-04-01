import 'dart:async';

import 'package:get/get.dart' hide navigator;
import 'package:mediasoup_update/features/signaling/web_socket.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';
import 'package:mediasoup_update/helper.dart';

import 'call_info_controller.dart';
import 'device_controller.dart';
import 'peer_controller.dart';
import 'producer_controller.dart';

class CallingController extends GetxController {
  late DeviceController _deviceController;
  late ProducerController _producerController;
  late PeerController _peerController;
  late CallInfoController _callInfoController;

  Device? _mediasoupDevice;
  WebSocket? _webSocket;
  Transport? _sendTransport;
  Transport? _recvTransport;
  bool _produce = false;
  final bool _closed = false;
  final bool _consume = true;

  // Is loading webcam
  RxBool webcamInProgress = RxBool(false);

  // Renderer
  final RTCVideoRenderer renderer = RTCVideoRenderer();

  @override
  void onInit() {
    super.onInit();
    _initRenderers();
    _initController();
    _setup();
  }

  @override
  void onClose() {
    super.onClose();
    close();
  }

  void _initController() {
    _deviceController = Get.put<DeviceController>(DeviceController());
    _producerController = Get.put<ProducerController>(ProducerController());
    _peerController = Get.put<PeerController>(PeerController());
    _callInfoController = Get.put<CallInfoController>(CallInfoController());
  }

  _initRenderers() async {
    await renderer.initialize();
  }

  void _setup() {
    join();
    _deviceController.selectedAudioInput.stream.listen((MediaDeviceInfo? audioInput) async {
      if (audioInput != null && audioInput.deviceId != _deviceController.audioInputDeviceId) {
        await disableMic();
        enableMic();
      }
    });
    _deviceController.selectedAudioInput.stream.listen((MediaDeviceInfo? videoInput) async {
      if (videoInput != null && videoInput.deviceId != _deviceController.videoInputDeviceId) {
        await disableWebcam();
        enableWebcam();
      }
    });
  }

  void close() {
    if (_closed) {
      return;
    }

    _webSocket?.close();
    _sendTransport?.close();
    _recvTransport?.close();
  }

  Future<void> disableMic() async {
    if (_producerController.mic.value == null) {
      return;
    }
    String micId = _producerController.mic.value!.id;

    _producerController.removeMic();

    try {
      await _webSocket!.socket.request('closeProducer', {
        'producerId': micId,
      });
    } catch (error) {
      appPrint(error);
    }
  }

  Future<void> disableWebcam() async {
    if (_producerController.webcam.value == null) {
      return;
    }
    webcamInProgress.value = true;
    String webcamId = _producerController.webcam.value!.id;

    _producerController.removeWebcame();

    try {
      await _webSocket!.socket.request('closeProducer', {
        'producerId': webcamId,
      });
    } finally {
      webcamInProgress.value = false;
    }
  }

  Future<void> muteMic() async {
    _producerController.pauseMic();

    try {
      await _webSocket!.socket.request('pauseProducer', {
        'producerId': _producerController.mic.value!.id,
      });
    } catch (error) {
      appPrint(error);
    }
  }

  Future<void> unmuteMic() async {
    _producerController.resumeMic();

    try {
      await _webSocket!.socket.request('resumeProducer', {
        'producerId': _producerController.mic.value!.id,
      });
    } catch (error) {
      appPrint(error);
    }
  }

  void _producerCallback(Producer producer) {
    if (producer.source == 'webcam') {
      webcamInProgress.value = false;
    }
    producer.on('trackended', () {
      disableMic().catchError((data) {});
    });
    _producerController.updateProducer(producer);
  }

  void _consumerCallback(Consumer consumer, [dynamic accept]) {
    ScalabilityMode scalabilityMode = ScalabilityMode.parse(consumer.rtpParameters.encodings.first.scalabilityMode);

    accept({});

    _peerController.addConsummer(peerId: consumer.peerId, consumer: consumer);
  }

  Future<MediaStream> createAudioStream() async {
    _deviceController.audioInputDeviceId = _deviceController.selectedAudioInput.value?.deviceId;
    Map<String, dynamic> mediaConstraints = {
      'audio': {
        'optional': [
          {
            'sourceId': _deviceController.audioInputDeviceId,
          },
        ],
      },
    };

    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    return stream;
  }

  Future<MediaStream> createVideoStream() async {
    _deviceController.videoInputDeviceId = _deviceController.selectedVideoInput.value?.deviceId;
    Map<String, dynamic> mediaConstraints = <String, dynamic>{
      'audio': false,
      'video': {
        'mandatory': {
          'minWidth': '1280',
          'minHeight': '720',
          'minFrameRate': '30',
        },
        'optional': [
          {
            'sourceId': _deviceController.videoInputDeviceId,
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
    webcamInProgress.value = true;
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
      webcamInProgress.value = true;
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
        'displayName': _callInfoController.me.name,
        'device': {
          'name': "Flutter",
          'flag': 'flutter',
          'version': '0.8.0',
        },
        'rtpCapabilities': _mediasoupDevice!.rtpCapabilities.toMap(),
        'sctpCapabilities': _mediasoupDevice!.sctpCapabilities.toMap(),
      });

      response['peers'].forEach((value) {
        _peerController.addPeer(value);
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
    _webSocket = WebSocket(
      peerId: _callInfoController.peerId,
      roomId: _callInfoController.roomId,
      url: _callInfoController.socket,
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
            _peerController.removeConsummer(consumerId);

            break;
          }
        case 'consumerPaused':
          {
            String consumerId = notification['data']['consumerId'];
            _peerController.pauseConsummer(consumerId);
            break;
          }

        case 'consumerResumed':
          {
            String consumerId = notification['data']['consumerId'];
            _peerController.resumeConsummer(consumerId);
            break;
          }

        case 'newPeer':
          {
            final Map<String, dynamic> newPeer = Map<String, dynamic>.from(notification['data']);
            _peerController.addPeer(newPeer);
            break;
          }

        case 'peerClosed':
          {
            String peerId = notification['data']['peerId'];
            _peerController.removePeer(peerId);
            break;
          }

        default:
          break;
      }
    };
  }
}
