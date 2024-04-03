import 'package:protoo_client/protoo_client.dart' as protoo_client;

class WebSocket {
  final String peerId;
  final String roomId;
  final String url;
  late protoo_client.Peer _protoo;
  Function()? onOpen;
  Function()? onFail;
  Function()? onDisconnected;
  Function()? onClose;
  Function(dynamic request, dynamic accept, dynamic reject)? onRequest; // request, accept, reject
  Function(dynamic notification)? onNotification;

  protoo_client.Peer get socket => _protoo;

  WebSocket({required this.peerId, required this.roomId, required this.url}) {
    _protoo = protoo_client.Peer(
      protoo_client.Transport('$url/?roomId=$roomId&peerId=$peerId'),
    );

    _protoo.on('open', () => onOpen?.call());
    _protoo.on('failed', () => onFail?.call());
    _protoo.on('disconnected', () => onClose?.call());
    _protoo.on('close', () => onClose?.call());
    _protoo.on('request', (request, accept, reject) => onRequest?.call(request, accept, reject));
    _protoo.on('notification', (request, accept, reject) => onNotification?.call(request));
  }

  void close() {
    _protoo.close();
  }
}
