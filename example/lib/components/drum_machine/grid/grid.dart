import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'cell.dart';

class Grid extends StatelessWidget {
  Grid({
    Key? key,
    required this.getVelocity,
    required this.columnLabels,
    required this.stepCount,
    required this.currentStep,
    required this.onChange,
    required this.onNoteOn,
    required this.onNoteOff,
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

        return ListView.builder(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 16),
            shrinkWrap: true,
            itemCount: stepCount,
            itemBuilder: (BuildContext context, int step) {
              final List<Widget> cellWidgets = [];

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
              return Row(children: cellWidgets);
            });
      },
    );
  }
}
