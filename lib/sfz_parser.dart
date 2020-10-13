import 'dart:io';
import 'dart:math';
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

/// Based on AudioKit Sampler's SFZ parser
/// https://github.com/AudioKit/AudioKit/blob/c2a7712ead3ccca86eb437bfd03bf0c09d6fba6c/AudioKit/Common/Nodes/Playback/Samplers/Sampler/AKSampler%2BSFZ.swift
Future<SfzParseResult> parseSfz(String sfzFilename, bool isAsset) async {
  String sfzContents;

  if (isAsset) {
    sfzContents = await rootBundle.loadString(sfzFilename);
  } else {
    sfzContents = await File(sfzFilename).readAsString();
  }

  var minimumNoteNumber = 0;
  var maximumNoteNumber = 127;
  var noteNumber = 60;
  var minimumVelocity = 0;
  var maximumVelocity = 127;
  String samplePath;
  var loopMode = '';
  var loopStartPoint = 0.0;
  var loopEndPoint = 0.0;

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
      noteNumber = int.parse(value);
      minimumNoteNumber = noteNumber;
      maximumNoteNumber = noteNumber;
    } else if (key == 'lokey') {
      minimumNoteNumber = int.parse(value);
    } else if (key == 'hikey') {
      maximumNoteNumber = int.parse(value);
    } else if (key == 'pitch_keycenter') {
      noteNumber = int.parse(value);
    } else if (key == 'lovel') {
      minimumVelocity = int.parse(value);
    } else if (key == 'hivel') {
      maximumVelocity = int.parse(value);
    } else if (key == 'loop_mode') {
      loopMode = value;
    } else if (key == 'loop_start') {
      loopStartPoint = double.parse(value);
    } else if (key == 'loop_end') {
      loopEndPoint = double.parse(value);
    } else if (key == 'sample') {
      samplePath =
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
      for (var part in trimmed.substring(7).split(RegExp(r'\s+'))) {
        handleOpcode(part, lineNumber);
      }
    } else if (trimmed.startsWith('<region>')) {
      // parse a <region> line

      samplePath = null;
      final parts =
        trimmed
          .substring(8)
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty);

      for (var part in parts) {
        handleOpcode(part, lineNumber);
      }

      final noteFrequency = 440.0 *
        pow(2.0, (noteNumber.roundToDouble() - 69.0) / 12.0);

      if (samplePath == null) {
        warnings.add(MissingOpcodeWarning('sample', lineNumber));
        continue;
      }

      final sampleAbsolutePath = samplesBaseUrl.resolve(samplePath).path.toString();

      sampleDescriptors.add(
        SampleDescriptor(
          filename: sampleAbsolutePath,
          isAsset: isAsset,
          noteNumber: noteNumber,
          noteFrequency: noteFrequency,
          minimumNoteNumber: minimumNoteNumber,
          maximumNoteNumber: maximumNoteNumber,
          minimumVelocity: minimumVelocity,
          maximumVelocity: maximumVelocity,
          isLooping: loopMode != '',
          loopStartPoint: loopStartPoint,
          loopEndPoint: loopEndPoint,
          startPoint: 0.0,
          endPoint: 0.0,
        ));
    }
  }

  return SfzParseResult(
    sampleDescriptors: sampleDescriptors,
    warnings: warnings,
  );
}