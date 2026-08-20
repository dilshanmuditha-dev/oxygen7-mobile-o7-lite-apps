// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Homepage
class YoutubePlay extends StatefulWidget {
  const YoutubePlay({Key? key}) : super(key: key);

  @override
  _YoutubePlayState createState() => _YoutubePlayState();
}

class _YoutubePlayState extends State<YoutubePlay> {
  // late YoutubePlayerController _controller;
  // Controllers commented out - not currently in use
  // late TextEditingController _idController;
  // late TextEditingController _seekToController;

  @override
  void initState() {
    super.initState();

    // _controller = YoutubePlayerController(
    //   initialVideoId: "diSoXAS-Cjk",
    //   flags: const YoutubePlayerFlags(
    //     mute: false,
    //     autoPlay: true,
    //     disableDragSeek: false,
    //     loop: false,
    //     isLive: false,
    //     forceHD: false,
    //     enableCaption: true,
    //   ),
    // )..addListener(listener);
    // _idController = TextEditingController();
    // _seekToController = TextEditingController();
    // _controller.toggleFullScreenMode();
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page.
    // _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    // _controller.dispose();
    // _idController.dispose();
    // _seekToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
    //  return YoutubePlayerBuilder(
    //   onExitFullScreen: () {},
    //   player: YoutubePlayer(
    //     controller: _controller,
    //     showVideoProgressIndicator: true,
    //     progressIndicatorColor: Colors.blueAccent,
    //     topActions: <Widget>[
    //       const SizedBox(width: 8.0),
    //       Expanded(
    //         child: Text(
    //           _controller.metadata.title,
    //           style: const TextStyle(
    //             color: Colors.white,
    //             fontSize: 18.0,
    //           ),
    //           overflow: TextOverflow.ellipsis,
    //           maxLines: 1,
    //         ),
    //       ),
    //       IconButton(
    //         icon: const Icon(
    //           Icons.settings,
    //           color: Colors.white,
    //           size: 25.0,
    //         ),
    //         onPressed: () {
    //           log('Settings Tapped!');
    //         },
    //       ),
    //     ],
    //     onReady: () {
    //       _isPlayerReady = true;
    //     },
    //   ),
    //   builder: (context, player) => player,
    // );
  }
}
