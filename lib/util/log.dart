// Log Tag
import 'dart:convert';
import 'package:flutter/foundation.dart';


final Log pLog = Log();

// 태그는 index 를 가지며 
// index 가 낮을수록 앞에 출력 됨
enum Tag {

// AD -------------------------------------------------------------------------
  AD,

// DB -------------------------------------------------------------------------
  DB,

// API ------------------------------------------------------------------------
  API,

  SUCCESS,
  FAIL,

  REQUEST,
  RESPONSE,
  ERROR,

  GET,
  POST,
  PUT,
  DELETE,
  UPLOAD,
  FILE,

// Firebase ----------------------------------------------------------------
  FIREBASE,
  FCM,

// Notification --------------------------------------------------------------
  NOTI,
  REMINDER,

// Network --------------------------------------------------------------------
  NETWORK,

// View -----------------------------------------------------------------------
  GROUP,
  SCREEN,
  CALENDAR,
  EVENT,
  CAMERA,
  TODO,

// Floppy Category - 기능 or 화면 -----------------------------------------------
  LOGIN,
  SPACE,
  SUBSCRIPTION,

// Router ---------------------------------------------------------------------
  ROUTER,

// None -----------------------------------------------------------------------
  NONE;

  String get title => toString().split('.').last;
}

// Log Level
enum LogLevel {
  TRACE,
  DEBUG,
  WARNING,
  ERROR,
  FATAL,
  NONE;

  String get title {
    switch (this) {
      case LogLevel.TRACE:
        return 'T';
      case LogLevel.DEBUG:
        return 'D';
      case LogLevel.WARNING:
        return 'W';
      case LogLevel.ERROR:
        return 'E';
      case LogLevel.FATAL:
        return 'F';
      case LogLevel.NONE:
        return 'N';
    }
  }
}

// Log Class
class Log {
  // static LogLevel _logLevel = kDebugMode ? LogLevel.TRACE : LogLevel.ERROR;
  static LogLevel _logLevel = LogLevel.TRACE;
  static Set<Tag> _tags = {};

  Log._internal();

  static final Log _instance = Log._internal();

  factory Log() => _instance;

  static void setLogLevel(LogLevel logLevel) {
    _logLevel = logLevel;
  }

  // Tag 설정 메서드
  Log tag(Tag tag) {
    _tags.add(tag);
    return _instance;
  }

  // 다중 Tag 설정 메서드
  Log tags(List<Tag> tags) {
    _tags.addAll(tags);
    return _instance;
  }

  void _printLog(String message, LogLevel logLevel, {bool showStack = kDebugMode}) {
    var tags = _tags.toList();
    _tags.clear();

    if (tags.isEmpty) {
      tags = [Tag.NONE];
    }

    tags.sort((a, b) => a.index.compareTo(b.index));

    if (_shouldNotPrintLog(logLevel)) {
      tags.clear();
      return;
    }

    final tagString = tags.map((tag) => "[${tag.title}]").join();
    final emoji = logLevel.index > LogLevel.DEBUG.index ? '❌' : '🟢';
    final location = showStack ? getCalledFileName(3) : {};
    final splitMsg = message.split('\n');

    for (int i = 0; i < splitMsg.length; i++) {
      final msg = splitMsg[i];
      final logMessage = showStack
          ? "$emoji [${logLevel.title}] $tagString [${location['file'].replaceAll('.dart', '')}:${location['line']}]: - $msg"
          : "$emoji [${logLevel.title}] $tagString: - $msg";

      // const subStringCount = 120;
      // debugPrint(logMessage.length > subStringCount ? logMessage.substring(0, subStringCount) : logMessage);
      debugPrint(logMessage);
    }

    tags.clear();
  }

  void t(String message) {
    _printLog(message, LogLevel.TRACE);
  }

  void d(String message) {
    _printLog(message, LogLevel.DEBUG);
  }

  void w(String message) {
    _printLog(message, LogLevel.WARNING);
  }

  void e(String message) {
    _printLog(message, LogLevel.ERROR);
  }

  void f(String message) {
    _printLog(message, LogLevel.FATAL);
  }

  void xt(String message) {
    _printLog(message, LogLevel.TRACE, showStack: false);
  }

  void xd(String message) {
    _printLog(message, LogLevel.DEBUG, showStack: false);
  }

  void xw(String message) {
    _printLog(message, LogLevel.WARNING, showStack: false);
  }

  void xe(String message) {
    _printLog(message, LogLevel.ERROR, showStack: false);
  }

  void xf(String message) {
    _printLog(message, LogLevel.FATAL, showStack: false);
  }

  bool _shouldNotPrintLog(LogLevel logLevel) {
    switch (_logLevel) {
      case LogLevel.TRACE:
        return false;
      case LogLevel.DEBUG:
        return logLevel == LogLevel.TRACE;
      case LogLevel.WARNING:
        return logLevel == LogLevel.TRACE || logLevel == LogLevel.DEBUG;
      case LogLevel.ERROR:
        return logLevel == LogLevel.TRACE ||
            logLevel == LogLevel.DEBUG ||
            logLevel == LogLevel.WARNING;
      case LogLevel.FATAL:
        return logLevel != LogLevel.FATAL;
      case LogLevel.NONE:
        return true;
    }
  }

  Map<String, String> getCalledFileName(int stackCount) {
    try {
      throw Exception(); // 스택 트레이스를 생성
    } catch (e, stackTrace) {
      const unknownName = "unknown file";
      const unknownLine = 'unknown line';
      final stacks = stackTrace.toString().split('\n'); // 호출 정보를 포함한 두 번째 줄
      if (stacks.length < stackCount) {
        return {
          'file': unknownName,
          'line': unknownLine,
        };
      }
      final match = RegExp(r'(.+?):(\d+):\d+')
          .firstMatch(stacks[stackCount]); // 패키지와 라인 번호 추출
      if (match != null) {
        final split = (match.group(1) ?? unknownName).split('(');
        final package =
            split.isNotEmpty ? split[split.length - 1] : unknownName;
        final packageSplit = package.split('/');
        final file = packageSplit.isNotEmpty
            ? packageSplit[packageSplit.length - 1]
            : unknownName;
        return {
          'file': file,
          'line': match.group(2) ?? unknownLine,
        };
      }
    }
    return {'package': 'unknown_package', 'line': 'unknown_line'};
  }
}

const String _prettyLinePrefix = '│ ';
const int _prettyBoxWidth = 55;

extension prettyJson on Map<String, dynamic> {
  String toPrettyString({bool withBoxSeparator = true}) {
    // String 값이 50자를 넘으면 자르고 ... 추가
    final truncatedMap = _truncateLongStrings(this);
    final json = const JsonEncoder.withIndent('  ').convert(truncatedMap);
    final body =
        json.split('\n').map((line) => '$_prettyLinePrefix$line').join('\n');
    return _wrapWithBoxIf(body, withBoxSeparator);
  }

  String toPrettyFullString({bool withBoxSeparator = true}) {
    final json = const JsonEncoder.withIndent('  ').convert(this);
    final body =
        json.split('\n').map((line) => '$_prettyLinePrefix$line').join('\n');
    return _wrapWithBoxIf(body, withBoxSeparator);
  }

  String _wrapWithBoxIf(String body, bool withBoxSeparator) {
    if (!withBoxSeparator) return body;
    final line = '─' * _prettyBoxWidth;
    return '┌$line\n$body\n└$line';
  }

  Map<String, dynamic> _truncateLongStrings(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is String && value.length > 50) {
        result[entry.key] = '${value.substring(0, 50)}...';
      } else if (value is Map<String, dynamic>) {
        result[entry.key] = _truncateLongStrings(value);
      } else if (value is List) {
        result[entry.key] = value.map((item) {
          if (item is String && item.length > 50) {
            return '${item.substring(0, 50)}...';
          } else if (item is Map<String, dynamic>) {
            return _truncateLongStrings(item);
          }
          return item;
        }).toList();
      } else {
        result[entry.key] = '$value';
      }
    }
    return result;
  }
}