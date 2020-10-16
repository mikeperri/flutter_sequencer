import 'package:flutter/foundation.dart';
import 'dart:math';

double get12TETFrequency(int noteNumber, [a4Frequency = 440.0]) {
  return a4Frequency * pow(2.0, (noteNumber.roundToDouble() - 69.0) / 12.0);
}

/// Contains information about a sample file. Gets converted to AudioKit
/// Sampler's AKSampleDescriptor.
class SampleDescriptor {
  SampleDescriptor({
    @required this.filename,
    @required this.isAsset,
    @required this.noteNumber,
    double noteFrequency,
    int minimumNoteNumber,
    int maximumNoteNumber,
    int minimumVelocity,
    int maximumVelocity,
    bool isLooping,
    double loopStartPoint,
    double loopEndPoint,
    double startPoint,
    double endPoint,
  }) {
    this.noteFrequency = noteFrequency ?? get12TETFrequency(noteNumber);
    this.minimumNoteNumber = minimumNoteNumber ?? 0;
    this.maximumNoteNumber = minimumNoteNumber ?? 127;
    this.minimumVelocity = minimumVelocity ?? 0;
    this.maximumVelocity = maximumVelocity ?? 0;
    this.isLooping = isLooping ?? false;
    this.loopStartPoint = loopStartPoint ?? 0.0;
    this.loopEndPoint = loopEndPoint ?? 0.0;
    this.startPoint = startPoint ?? 0.0;
    this.endPoint = endPoint ?? 0.0;
  }

  String filename;
  bool isAsset;

  // AKSampleDescriptor properties
  int noteNumber;
  double noteFrequency;

  int minimumNoteNumber, maximumNoteNumber;
  int minimumVelocity, maximumVelocity;

  bool isLooping;
  double loopStartPoint, loopEndPoint;
  double startPoint, endPoint;
}
