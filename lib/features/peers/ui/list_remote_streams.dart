import 'package:get/get.dart';
import 'package:mediasoup_update/features/peers/peer_controller.dart';
import 'package:mediasoup_update/features/peers/ui/remote_stream.dart';
import 'package:flutter/material.dart';
import 'package:mediasoup_update/features/peers/enitity/peer.dart';

class ListRemoteStreams extends GetView<PeerController> {
  const ListRemoteStreams({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final Map<String, Peer> peers = controller.peers;
        final bool small = MediaQuery.of(context).size.width < 800;
        final bool horizontal = MediaQuery.of(context).orientation == Orientation.landscape;

        if (small && peers.length == 1) {
          return RemoteStream(
            key: ValueKey(peers.keys.first),
            peer: peers.values.first,
          );
        }

        final height = MediaQuery.of(context).size.height;
        final width = MediaQuery.of(context).size.width;

        if (small && horizontal) {
          return MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: GridView.count(
              crossAxisCount: 2,
              children: peers.values.map((peer) {
                return SizedBox(
                  key: ValueKey('${peer.id}_container'),
                  width: width / 2,
                  height: peers.length <= 2 ? height : height / 2,
                  child: RemoteStream(
                    key: ValueKey(peer.id),
                    peer: peer,
                  ),
                );
              }).toList(),
            ),
          );
        }

        if (small) {
          return MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView.builder(
              itemBuilder: (context, index) {
                final peerId = peers.keys.elementAt(index);
                return SizedBox(
                  key: ValueKey('${peerId}_container'),
                  width: double.infinity,
                  height: peers.length > 2 ? height / 3 : height / 2,
                  child: RemoteStream(
                    key: ValueKey(peerId),
                    peer: peers[peerId]!,
                  ),
                );
              },
              itemCount: peers.length,
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
            ),
          );
        }
        return Center(
          child: Wrap(
            spacing: 10,
            children: [
              for (Peer peer in peers.values)
                SizedBox(
                  key: ValueKey('${peer.id}_container'),
                  width: 450,
                  height: 380,
                  child: RemoteStream(
                    key: ValueKey(peer.id),
                    peer: peers[peer.id]!,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
