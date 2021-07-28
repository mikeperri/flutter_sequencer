/// Learn more about the SFZ format here: <https://sfzformat.com/headers/>

String opcodeMapToString(Map<String, String>? opcodeMap) {
  if (opcodeMap == null) {
    return '';
  } else {
    return opcodeMap.entries
        .map((entry) => '${entry.key}=${entry.value}\n')
        .join('');
  }
}

class SfzRegion {
  SfzRegion({
    this.sample,
    this.key,
    this.lokey,
    this.hikey,
    this.lovel,
    this.hivel,
    this.loopStart,
    this.loopEnd,
    this.otherOpcodes,
  });

  String? sample;
  int? key;
  int? lokey, hikey;
  int? lovel, hivel;
  double? loopStart, loopEnd;
  Map<String, String>? otherOpcodes;

  String buildString() {
    return '<region>\n' +
        (sample != null ? 'sample=$sample\n' : '') +
        (key != null ? 'key=$key\n' : '') +
        (lokey != null ? 'lokey=$lokey\n' : '') +
        (hikey != null ? 'hikey=$hikey\n' : '') +
        (lovel != null ? 'lovel=$lovel\n' : '') +
        (hivel != null ? 'hivel=$hivel\n' : '') +
        (loopStart != null ? 'loop_start=$loopStart\n' : '') +
        (loopEnd != null ? 'loop_end=$loopEnd\n' : '') +
        (opcodeMapToString(otherOpcodes));
  }
}

class SfzGroup {
  SfzGroup({
    this.opcodes,
    required this.regions,
  });

  Map<String, String>? opcodes;
  List<SfzRegion> regions;

  String buildString() {
    return '<group>\n' +
        (opcodeMapToString(opcodes)) +
        regions.map((r) => r.buildString()).join('');
  }
}

class SfzControl {
  SfzControl({
    this.opcodes,
  });

  Map<String, String>? opcodes;

  String buildString() {
    return '<control>\n' +
      (opcodeMapToString(opcodes));
  }
}

class SfzGlobal {
  SfzGlobal({
    this.opcodes,
  });

  Map<String, String>? opcodes;

  String buildString() {
    return '<global>\n' +
      (opcodeMapToString(opcodes));
  }
}

class SfzEffect {
  SfzEffect({
    this.opcodes,
  });

  Map<String, String>? opcodes;

  String buildString() {
    return '<effect>\n' +
      (opcodeMapToString(opcodes));
  }
}

class SfzCurve {
  SfzCurve({
    this.opcodes,
  });

  Map<String, String>? opcodes;

  String buildString() {
    return '<curve>\n' +
      (opcodeMapToString(opcodes));
  }
}

/// Used to build an SFZ. Note that if lokey or hikey are not set on a given
/// region, they will be set automatically.
class Sfz {
  final List<SfzGroup> groups;
  final List<SfzControl> controls;
  final List<SfzEffect> effects;
  final List<SfzCurve> curves;
  final SfzGlobal? global;

  Sfz({
    required this.groups,
    this.controls = const [],
    this.effects = const [],
    this.curves = const [],
    this.global,
  });

  void _setNoteRanges() {
    final allRegions = [];

    groups.forEach((g) => allRegions.addAll(g.regions));

    allRegions.sort((a, b) => a.key - b.key);
    allRegions.asMap().forEach((index, sd) {
      final prevSd = index > 0 ? allRegions[index - 1] : null;
      final nextSd =
          index < allRegions.length - 1 ? allRegions[index + 1] : null;

      if (sd.lokey == null) {
        if (prevSd == null) {
          sd.lokey = 0;
        } else {
          sd.lokey = ((sd.key + prevSd.key) / 2).floor() + 1;
        }
      }

      if (sd.hikey == null) {
        if (nextSd == null) {
          sd.hikey = 127;
        } else {
          sd.hikey = ((nextSd.key + sd.key) / 2).floor();
        }
      }
    });
  }

  String buildString() {
    _setNoteRanges();

    return
      (global?.buildString() ?? '') +
      controls.map((c) => c.buildString()).join('') +
      effects.map((e) => e.buildString()).join('') +
      curves.map((c) => c.buildString()).join('') +
      groups.map((g) => g.buildString()).join('');
  }
}
