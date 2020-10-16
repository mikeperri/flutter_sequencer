import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

import 'models/sample_descriptor.dart';

/// Base class for SFZ parser warnings.
class BaseSfzWarning {
  int lineNumber;

  BaseSfzWarning(this.lineNumber);
}

/// Warns that there was an opcode in the SFZ that this library did not know how
/// to handle and ignored.
class UnknownOpcodeWarning extends BaseSfzWarning {
  String opcode;

  UnknownOpcodeWarning(this.opcode, int lineNumber) : super(lineNumber);
}

/// Warns that an opcode was expected, but was not found.
class MissingOpcodeWarning extends BaseSfzWarning {
  String opcode;

  MissingOpcodeWarning(this.opcode, int lineNumber) : super(lineNumber);
}

/// Represents the result of parsing an SFZ.
class SfzParseResult {
  List<SampleDescriptor> sampleDescriptors;
  List<BaseSfzWarning> warnings;

  SfzParseResult({ this.sampleDescriptors, this.warnings });
}

class SfzParserState {
  int noteNumber;
  int minimumNoteNumber;
  int maximumNoteNumber;
  int minimumVelocity;
  int maximumVelocity;
  String samplePath;
  String loopMode;
  double loopStartPoint;
  double loopEndPoint;

  resetForGroup() {
    noteNumber = null;
    minimumNoteNumber = null;
    maximumNoteNumber = null;
    minimumVelocity = null;
    maximumVelocity = null;
    loopMode = null;
    loopStartPoint = null;
    loopEndPoint = null;
  }

  resetForRegion() {
    samplePath = null;
  }
}

/// Based on AudioKit Sampler's SFZ parser
/// https://github.com/AudioKit/AudioKit/blob/c2a7712ead3ccca86eb437bfd03bf0c09d6fba6c/AudioKit/Common/Nodes/Playback/Samplers/Sampler/AKSampler%2BSFZ.swift
Future<SfzParseResult> parseSfz(String sfzFilename, bool isAsset) async {
  String sfzContents;

  if (isAsset) {
    sfzContents = await rootBundle.loadString(sfzFilename);
  } else {
    sfzContents = await File(sfzFilename).readAsString();
  }

  final state = SfzParserState();

  final samplesBaseUrl = Uri.file(sfzFilename).resolve('.');
  final lines = sfzContents.split('\n');
  final warnings = <BaseSfzWarning>[];
  final sampleDescriptors = <SampleDescriptor>[];

  final handleOpcode = (String opcode, int lineNumber) {
    final keyAndValue = opcode.split('=');

    if (keyAndValue.length != 2) {
      warnings.add(UnknownOpcodeWarning(keyAndValue[0], lineNumber));
      return;
    }

    final key = keyAndValue[0];
    final value = keyAndValue[1];
    if (key == 'key') {
      state.noteNumber = int.parse(value);
      state.minimumNoteNumber = state.noteNumber;
      state.maximumNoteNumber = state.noteNumber;
    } else if (key == 'lokey') {
      state.minimumNoteNumber = int.parse(value);
    } else if (key == 'hikey') {
      state.maximumNoteNumber = int.parse(value);
    } else if (key == 'pitch_keycenter') {
      state.noteNumber = int.parse(value);
    } else if (key == 'lovel') {
      state.minimumVelocity = int.parse(value);
    } else if (key == 'hivel') {
      state.maximumVelocity = int.parse(value);
    } else if (key == 'loop_mode') {
      state.loopMode = value;
    } else if (key == 'loop_start') {
      state.loopStartPoint = double.parse(value);
    } else if (key == 'loop_end') {
      state.loopEndPoint = double.parse(value);
    } else if (key == 'sample') {
      state.samplePath =
        value.split('/').map((part) => Uri.encodeComponent(part)).join('/');
    } else {
      warnings.add(UnknownOpcodeWarning(key, lineNumber));
    }
  };

  for (var lineNumber = 0; lineNumber < lines.length; lineNumber++) {
    final line = lines[lineNumber];
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('//')) {
      continue;
    }

    if (trimmed.startsWith('<group>')) {
      // parse a <group> line
      state.resetForGroup();
      for (var part in trimmed.substring(7).split(RegExp(r'\s+'))) {
        handleOpcode(part, lineNumber);
      }
    } else if (trimmed.startsWith('<region>')) {
      state.resetForRegion();
      // parse a <region> line
      final parts =
        trimmed
          .substring(8)
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty);

      for (var part in parts) {
        handleOpcode(part, lineNumber);
      }

      if (state.samplePath == null) {
        warnings.add(MissingOpcodeWarning('sample', lineNumber));
        continue;
      }

      final sampleAbsolutePath =
        samplesBaseUrl.resolve(state.samplePath).path.toString();

      sampleDescriptors.add(
        SampleDescriptor(
          filename: sampleAbsolutePath,
          isAsset: isAsset,
          noteNumber: state.noteNumber,
          minimumNoteNumber: state.minimumNoteNumber,
          maximumNoteNumber: state.maximumNoteNumber,
          minimumVelocity: state.minimumVelocity,
          maximumVelocity: state.maximumVelocity,
          isLooping: state.loopMode != null,
          loopStartPoint: state.loopStartPoint,
          loopEndPoint: state.loopEndPoint,
        ));
    }
  }

  return SfzParseResult(
    sampleDescriptors: sampleDescriptors,
    warnings: warnings,
  );
}