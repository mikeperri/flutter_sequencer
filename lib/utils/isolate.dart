import 'dart:async';
import 'dart:isolate';

/// These functions are copied from the 'isolate' library.
/// https://pub.dev/packages/isolate
/// https://github.com/dart-lang/isolate/blob/ca133acb5af3a60a026fa2aab12b81e60048b3be/lib/ports.dart#L162
/// I didn't import the actual library since it doesn't support null safety.

/// Copyright 2015, the Dart project authors.
///
/// Redistribution and use in source and binary forms, with or without
/// modification, are permitted provided that the following conditions are
/// met:
///
/// * Redistributions of source code must retain the above copyright
/// notice, this list of conditions and the following disclaimer.
/// * Redistributions in binary form must reproduce the above
/// copyright notice, this list of conditions and the following
/// disclaimer in the documentation and/or other materials provided
/// with the distribution.
/// * Neither the name of Google LLC nor the names of its
/// contributors may be used to endorse or promote products derived
/// from this software without specific prior written permission.
///
/// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
/// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
/// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
/// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
/// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
///   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
/// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
/// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
/// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
/// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
/// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

void _castComplete<R>(Completer<R> completer, Object value) {
  try {
    completer.complete(value as R);
  } catch (error, stack) {
    completer.completeError(error, stack);
  }
}

Future<R> singleResponseFuture<R>(void Function(SendPort responsePort) action,
  {Duration? timeout, R? timeoutValue}) {
  var completer = Completer<R>.sync();
  var responsePort = RawReceivePort();
  Timer? timer;
  var zone = Zone.current;
  responsePort.handler = (Object response) {
    responsePort.close();
    timer?.cancel();
    zone.run(() {
      _castComplete<R>(completer, response);
    });
  };
  if (timeout != null) {
    timer = Timer(timeout, () {
      responsePort.close();
      completer.complete(timeoutValue);
    });
  }
  try {
    action(responsePort.sendPort);
  } catch (error, stack) {
    responsePort.close();
    timer?.cancel();
    // Delay completion because completer is sync.
    scheduleMicrotask(() {
      completer.completeError(error, stack);
    });
  }
  return completer.future;
}
