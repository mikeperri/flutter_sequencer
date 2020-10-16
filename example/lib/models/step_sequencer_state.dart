class StepSequencerState {
  Map<int, Map<int, double>> stepNoteNumberVelocityMap = {};

  void setVelocity(int step, int noteNumber, double velocity) {
    var noteNumberVelocityMap = stepNoteNumberVelocityMap[step];

    if (noteNumberVelocityMap == null) {
      noteNumberVelocityMap = {};
      stepNoteNumberVelocityMap[step] = noteNumberVelocityMap;
    }

    noteNumberVelocityMap[noteNumber] = velocity;
  }

  double getVelocity(int step, int noteNumber) {
    if (stepNoteNumberVelocityMap[step] == null
      || stepNoteNumberVelocityMap[step][noteNumber] == null) {
      return 0;
    } else {
      return stepNoteNumberVelocityMap[step][noteNumber];
    }
  }

  void iterateEvents(Function(int step, int noteNumber, double velocity) callback) {
    stepNoteNumberVelocityMap.forEach((step, noteNumberVelocityMap) {
      noteNumberVelocityMap.forEach((noteNumber, velocity) {
        if (velocity > 0) {
          callback(step, noteNumber, velocity);
        }
      });
    });
  }
}