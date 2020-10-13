import 'package:flutter/foundation.dart';

/// Contains information about a sample file. Gets converted to AudioKit
/// Sampler's AKSampleDescriptor.
class SampleDescriptor {
  SampleDescriptor({
    @required this.filename,
    @required this.isAsset,
    @required this.noteNumber,
    @required this.noteFrequency,
    @required this.minimumNoteNumber,
    @required this.maximumNoteNumber,
    @required this.minimumVelocity,
    @required this.maximumVelocity,
    @required this.isLooping,
    @required this.loopStartPoint,
    @required this.loopEndPoint,
    @required this.startPoint,
    @required this.endPoint,
  });

  final String filename;
  final bool isAsset;

  // AKSampleDescriptor properties
  final int noteNumber;
  final double noteFrequency;

  final int minimumNoteNumber, maximumNoteNumber;
  final int minimumVelocity, maximumVelocity;

  final bool isLooping;
  final double loopStartPoint, loopEndPoint;
  final double startPoint, endPoint;
}
