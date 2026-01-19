import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class LogService {
  static final List<String> _logs = [];
  static final int _maxLogs = 1000; // Keep last 1000 log entries
  static StreamController<String>? _logController;
  static Stream<String>? _logStream;

  /// Initialize log service
  static void init() {
    _logController = StreamController<String>.broadcast();
    _logStream = _logController!.stream;
  }

  /// Add log entry
  static void _addLog(String message) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
    final logEntry = '[$timestamp] $message';
    
    _logs.add(logEntry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
    
    _logController?.add(logEntry);
  }

  /// Manually add log (for important events)
  static void log(String message) {
    _addLog(message);
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Log with prefix (for easier filtering)
  static void logWithPrefix(String prefix, String message) {
    log('[$prefix] $message');
  }

  /// Get all logs
  static List<String> getLogs() {
    return List.unmodifiable(_logs);
  }

  /// Get logs as string
  static String getLogsAsString() {
    return _logs.join('\n');
  }

  /// Get log stream
  static Stream<String>? getLogStream() {
    return _logStream;
  }

  /// Export logs to file
  static Future<File?> exportLogsToFile() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        // Fallback to app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final logDir = Directory('${appDir.path}/logs');
        if (!await logDir.exists()) {
          await logDir.create(recursive: true);
        }
        
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final file = File('${logDir.path}/ramadan_tracker_log_$timestamp.txt');
        await file.writeAsString(_getLogFileContent());
        return file;
      }

      // Try to save to Downloads folder (more accessible)
      final downloadsPath = '/storage/emulated/0/Download';
      final downloadsDir = Directory(downloadsPath);
      
      if (await downloadsDir.exists()) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final file = File('$downloadsPath/ramadan_tracker_log_$timestamp.txt');
        await file.writeAsString(_getLogFileContent());
        return file;
      }

      // Fallback to external storage
      final logDir = Directory('${directory.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${logDir.path}/ramadan_tracker_log_$timestamp.txt');
      await file.writeAsString(_getLogFileContent());
      return file;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error exporting logs: $e');
      }
      return null;
    }
  }

  /// Get log file content with header
  static String _getLogFileContent() {
    final buffer = StringBuffer();
    buffer.writeln('=' * 80);
    buffer.writeln('Ramadan Tracker - Debug Log');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('=' * 80);
    buffer.writeln();
    buffer.writeln('Total log entries: ${_logs.length}');
    buffer.writeln();
    buffer.writeln('=' * 80);
    buffer.writeln('LOG ENTRIES');
    buffer.writeln('=' * 80);
    buffer.writeln();
    buffer.writeln(_logs.join('\n'));
    return buffer.toString();
  }

  /// Clear logs
  static void clearLogs() {
    _logs.clear();
  }

  /// Dispose
  static void dispose() {
    _logController?.close();
    _logController = null;
    _logStream = null;
  }
}

