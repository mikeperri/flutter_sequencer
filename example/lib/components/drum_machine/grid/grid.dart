import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'cell.dart';

class Grid extends StatelessWidget {
  Grid({
    Key key,
    this.getVelocity,
    this.columnLabels,
    this.stepCount,
    this.currentStep,
    this.onChange,
    this.onNoteOn,
    this.onNoteOff,
  }) : super(key: key);

  final Function(int step, int col) getVelocity;
  final List<String> columnLabels;
  final int stepCount;
  final int currentStep;
  final Function(int, int, double) onChange;
  final Function(int) onNoteOn;
  final Function(int) onNoteOff;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnsCount = columnLabels.length;
        final cellSize = min(constraints.maxWidth / columnLabels.length, 50.0);
        final rowWidgets = new List<Widget>();

        // Build a row of label widgets
        final labelWidgets = new List<Widget>();
        for (var col = 0; col < columnsCount; col++) {
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

        rowWidgets.add(Row(children: labelWidgets));

        // Build a row of Cell widgets for each step
        for (var step = 0; step < stepCount; step++) {
          final cellWidgets = new List<Widget>();

          for (var col = 0; col < columnsCount; col++) {
            final velocity = getVelocity(step, col);

            final cellWidget = Cell(
              size: cellSize,
              velocity: velocity,
              isCurrentStep: step == currentStep,
              onChange: (velocity) => onChange(col, step, velocity),
            );

            cellWidgets.add(cellWidget);
          }

          rowWidgets.add(Row(children: cellWidgets));
        }

        return Column(children: rowWidgets);
      },
    );
  }
}