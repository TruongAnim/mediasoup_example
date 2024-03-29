import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';

import 'enitity/peer.dart';

class PeerController {
  RxString selectedOutputId = RxString('');
  RxMap<String, Peer> peers = RxMap<String, Peer>({});

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
}
