import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class LabelRow extends StatelessWidget {
  LabelRow({
    Key? key,
    required this.columnLabels,
    required this.cellSize,
    required this.onNoteOn,
    required this.onNoteOff,
  }) : super(key: key);

  final List<String> columnLabels;
  final Function(int) onNoteOn;
  final Function(int) onNoteOff;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    // Build a row of label widgets
    final List<Widget> labelWidgets = [];
    for (var col = 0; col < columnLabels.length; col++) {
      final labelWidget =
      Listener(
        onPointerDown: (d) => onNoteOn(col),
        onPointerUp: (d) => onNoteOff(col),
        child: Container(
          color: Colors.blue,
          width: cellSize,
          height: cellSize,
          child: Center(child: Text(columnLabels[col])),
        ),
      );

      labelWidgets.add(labelWidget);
    }

    return Row(children: labelWidgets);
  }
}
