class StepSequencerState {
  Map<int, Map<int, double>> stepPitchVelocityMap = {};

  void setVelocity(int step, int pitch, double velocity) {
    var pitchVelocityMap = stepPitchVelocityMap[step];

    if (pitchVelocityMap == null) {
      pitchVelocityMap = {};
      stepPitchVelocityMap[step] = pitchVelocityMap;
    }

    pitchVelocityMap[pitch] = velocity;
  }

  double getVelocity(int step, int pitch) {
    if (stepPitchVelocityMap[step] == null
      || stepPitchVelocityMap[step][pitch] == null) {
      return 0;
    } else {
      return stepPitchVelocityMap[step][pitch];
    }
  }

  void iterateEvents(Function(int step, int pitch, double velocity) callback) {
    stepPitchVelocityMap.forEach((step, pitchVelocityMap) {
      pitchVelocityMap.forEach((pitch, velocity) {
        if (velocity > 0) {
          callback(step, pitch, velocity);
        }
      });
    });
  }
}