import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';

class LogUtils {
  /// Shared encoder that renders JSON with a 2-space indentation.
  static const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');

  static void debugLog(dynamic message) {
    if (!kReleaseMode) {
      log(message.toString());
    }
  }

  static void debugLog2(String tag, dynamic message) {
    if (!kReleaseMode) {
      log('$tag: $message');
    }
  }

  /// Formats [data] as a single-line JSON string.
  ///
  /// [data] may be an already-decoded structure (Map/List) or a raw JSON
  /// string (which is normalized). If [data] cannot be interpreted as JSON, its
  /// `toString()` is returned unchanged so logging never throws.
  static String compactJson(dynamic data) {
    try {
      final decoded = data is String ? jsonDecode(data) : data;
      return jsonEncode(decoded);
    } catch (_) {
      return data?.toString() ?? 'null';
    }
  }

  /// Formats [data] as indented, multi-line JSON. See [compactJson] for the
  /// accepted input and fallback behavior.
  static String prettyJson(dynamic data) {
    try {
      final decoded = data is String ? jsonDecode(data) : data;
      return _prettyEncoder.convert(decoded);
    } catch (_) {
      return data?.toString() ?? 'null';
    }
  }

  /// Logs [data] as JSON (skipped in release builds).
  ///
  /// Emits a single compact line by default so it can be copied straight out of
  /// the console as valid JSON. This matters because each console line is
  /// prefixed by the platform (e.g. `I/flutter (1234):`), so multi-line output
  /// cannot be copied cleanly. Pass `pretty: true` for indented, multi-line
  /// output when console readability matters more than copying.
  ///
  /// [data] may be an already-decoded structure (Map/List) or a raw JSON
  /// string.
  static void jsonLog(dynamic data,
      {String name = 'JSON', bool pretty = false}) {
    if (kReleaseMode) return;

    if (!pretty) {
      // One line -> one console prefix, so the JSON copies out cleanly.
      debugPrint('$name::: ${compactJson(data)}');
      return;
    }

    debugPrint('$name:::');
    _printChunked(prettyJson(data));
  }

  /// Emits [message] via [debugPrint], splitting it into chunks that stay under
  /// a size safe for Android logcat, breaking on newlines so the JSON
  /// indentation stays readable.
  static void _printChunked(String message) {
    const int maxChunk = 800;
    if (message.length <= maxChunk) {
      debugPrint(message);
      return;
    }

    final buffer = StringBuffer();
    for (final line in message.split('\n')) {
      if (buffer.isNotEmpty && buffer.length + line.length + 1 > maxChunk) {
        debugPrint(buffer.toString());
        buffer.clear();
      }
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write(line);
    }
    if (buffer.isNotEmpty) debugPrint(buffer.toString());
  }
}
