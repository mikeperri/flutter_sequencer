import 'models/sample_descriptor.dart';

/// The base class for Instruments.
abstract class Instrument  {
  final String idOrPath;
  final bool isAsset;

  Instrument(this.idOrPath, this.isAsset);

  String get displayName {
    return idOrPath.split(RegExp('[\\\\/]')).last;
  }
}

/// Describes an instrument in SF2 format.
class Sf2Instrument extends Instrument {
  Sf2Instrument({ String path, bool isAsset })
    : super(path, isAsset);
}

/// Describes an instrument in SFZ format.
class SfzInstrument extends Instrument {
  SfzInstrument({ String path, bool isAsset })
    : super(path, isAsset);
}

/// Describes a sampler instrument. Use this to create a sampler dynamically
/// instead of using an SFZ file.
class SamplerInstrument extends Instrument {
  final List<SampleDescriptor> sampleDescriptors;

  SamplerInstrument({ String id, this.sampleDescriptors }) : super(id, false);
}

/// Describes an AudioUnit instrument (Apple platforms only.)
class AudioUnitInstrument extends Instrument {
  AudioUnitInstrument({ String manufacturerName, String componentName })
    : super('${manufacturerName}.${componentName}', false);
}
