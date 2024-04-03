import 'package:get/get.dart';
import 'package:mediasoup_update/config/routes/route_path/base_routers.dart';
import 'package:mediasoup_update/features/media_devices/ui/audio_input_selector.dart';
import 'package:mediasoup_update/features/media_devices/ui/audio_output_selector.dart';
import 'package:mediasoup_update/features/media_devices/ui/video_input_selector.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';

class Welcome extends StatefulWidget {
  const Welcome({Key? key}) : super(key: key);

  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  final TextEditingController _textEditingController = TextEditingController();
  String url = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'mediasoup-client-flutter',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        shadowColor: Colors.grey,
        elevation: 5,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.only(top: 15),
          margin: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.center,
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(
                    Radius.circular(10.0),
                  ),
                ),
                child: TextField(
                  style: const TextStyle(
                    // fontSize: 15.0,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(left: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    hintText: 'Room url (empty = random room)',
                    hintStyle: TextStyle(
                      fontSize: 15.0,
                      color: Colors.black.withAlpha(90),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    suffixIcon: url.isNotEmpty
                        ? GestureDetector(
                            child: const Icon(
                              Icons.close,
                              color: Colors.black,
                            ),
                            onTap: () {
                              _textEditingController.clear();
                              setState(() {
                                url = '';
                              });
                            },
                          )
                        : null,
                  ),
                  maxLines: 1,
                  onChanged: (value) {
                    setState(() {
                      url = value;
                    });
                  },
                  controller: _textEditingController,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.toNamed(
                    BaseRouters.ROOM,
                    arguments: {
                      'url': 'wss://v3demo.mediasoup.org:4443',
                      'peerId': randomAlpha(8).toLowerCase(),
                      'roomId': '1234567',
                      'id': '123',
                      'name': 'TruongAnim',
                      'socket': 'wss://v3demo.mediasoup.org:4443',
                      'roomUrl': 'https://v3demo.mediasoup.org/'
                    },
                  );
                },
                style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.black)),
                child: Text(url.isNotEmpty ? 'Join' : 'Join to Random Room'),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mic),
                      Text(
                        'Audio Input',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  const AudioInputSelector(),
                ],
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.videocam),
                      Text(
                        'Video Input',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  const VideoInputSelector(),
                ],
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.videocam),
                      Text(
                        'Audio Output',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  const AudioOutputSelector(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
