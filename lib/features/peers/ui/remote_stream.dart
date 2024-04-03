import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mediasoup_update/core/mediasoup/models/peer.dart';

class RemoteStream extends StatelessWidget {
  final Peer peer;

  const RemoteStream({required Key key, required this.peer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (peer.renderer != null && peer.video != null)
          RTCVideoView(
            peer.renderer!,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        else
          const FittedBox(
            fit: BoxFit.contain,
            child: Icon(
              Icons.person,
              // size: double.infinity,
            ),
          ),
        Positioned(
            bottom: 5,
            left: 2,
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    peer.displayName,
                    overflow: TextOverflow.fade,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${peer.device.name} ${peer.device.version}',
                    overflow: TextOverflow.fade,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ))
      ],
    );
  }
}
