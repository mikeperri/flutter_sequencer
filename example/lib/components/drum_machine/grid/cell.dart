import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sequencer_example/constants.dart';

class Cell extends StatelessWidget {
  Cell({
    Key? key,
    required this.size,
    required this.velocity,
    required this.isCurrentStep,
    required this.onChange,
  }) : super(key: key);

  final double size;
  final double velocity;
  final bool isCurrentStep;
  final Function(double) onChange;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color.lerp(isCurrentStep ? Colors.white30 : Colors.black,
            isCurrentStep ? Colors.blue : Colors.pink, velocity),
        border: Border.all(color: Colors.white70),
      ),
      child: Transform(
          transform:
              Matrix4.translationValues(0, (-1 * size * velocity) + 2, 0),
          child: Container(
              width: size,
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white))))),
    );

    return GestureDetector(
      onTap: () {
        final nextVelocity = velocity == 0.0 ? DEFAULT_VELOCITY : 0.0;

        onChange(nextVelocity);
      },
      onVerticalDragUpdate: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final yPos = renderBox.globalToLocal(details.globalPosition).dy;
        final nextVelocity = 1.0 - (yPos / size).clamp(0.0, 1.0);

        onChange(nextVelocity);
      },
      child: box,
    );
  }
}
