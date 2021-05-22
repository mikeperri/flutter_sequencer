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
    return stepNoteNumberVelocityMap[step]?[noteNumber] ?? 0;
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