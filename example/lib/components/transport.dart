import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Transport extends StatelessWidget {
  const Transport({
    Key? key,
    required this.isPlaying,
    required this.isLooping,
    required this.onTogglePlayPause,
    required this.onStop,
    required this.onToggleLoop,
  }) : super(key: key);

  final bool isPlaying;
  final bool isLooping;
  final Function() onTogglePlayPause;
  final Function() onStop;
  final Function() onToggleLoop;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onTogglePlayPause,
          color: Colors.pink,
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow)
        ),
        IconButton(
          icon: Icon(Icons.stop),
          onPressed: onStop,
          color: Colors.pink,
        ),
        IconButton(
          icon: Icon(Icons.repeat),
          onPressed: onToggleLoop,
          color: isLooping ? Colors.pink : Colors.black54,
        ),
      ],
    );
  }
}
