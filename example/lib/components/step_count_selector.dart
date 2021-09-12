import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class StepCountSelector extends StatelessWidget {
  const StepCountSelector({
    Key? key,
    required this.stepCount,
    required this.onChange,
  }) : super(key: key);

  final int stepCount;
  final Function(int) onChange;

  handleLess() {
    onChange(stepCount - 1);
  }

  handleMore() {
    onChange(stepCount + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Steps'),
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: handleLess,
        ),
        Text(stepCount.toString(),
            style: TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: handleMore,
        ),
      ],
    );
  }
}
