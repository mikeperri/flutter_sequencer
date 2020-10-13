import 'package:flutter/widgets.dart';

class PositionView extends StatelessWidget {
  PositionView({
    this.position
  });

  final double position;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 8.0),
      child: Text('Position: ${position.toStringAsFixed(3)}'),
    );
  }
}