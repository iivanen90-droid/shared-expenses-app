import 'dart:ui';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

final class ApplicationInitializerImpl implements ApplicationInitializer {
  ApplicationInitializerImpl({
    required this._startupStatus,
    required this._preparePreferences,
    required this._crashReporting,
  });
  final StartupStatus _startupStatus;
  final Future<void> Function() _preparePreferences;
  final CrashReportingService _crashReporting;
  Future<void>? _initialization;
  FlutterExceptionHandler? _previousFlutterHandler;
  FlutterExceptionHandler? _flutterHandler;
  ErrorCallback? _previousPlatformHandler;
  ErrorCallback? _platformHandler;

  @override
  Future<void> initialize() => _initialization ??= Future<void>.microtask(() async {
    _installErrorHandlers();
    try {
      await _preparePreferences();
      _startupStatus.markReady();
    } on Object {
      _initialization = null;
      rethrow;
    }
  });

  void _installErrorHandlers() {
    if (_flutterHandler != null) return;
    _previousFlutterHandler = FlutterError.onError;
    _previousPlatformHandler = PlatformDispatcher.instance.onError;
    _flutterHandler = (details) {
      _recordError(details.exception, details.stack ?? StackTrace.current, fatal: false);
      _previousFlutterHandler?.call(details);
    };
    _platformHandler = (error, stackTrace) {
      final recorded = _recordError(error, stackTrace, fatal: true);
      return _previousPlatformHandler?.call(error, stackTrace) ?? recorded;
    };
    FlutterError.onError = _flutterHandler;
    PlatformDispatcher.instance.onError = _platformHandler;
  }

  bool _recordError(Object error, StackTrace stackTrace, {required bool fatal}) {
    try {
      _crashReporting.recordError(error, stackTrace, fatal: fatal);
      return true;
    } on Object {
      // A failing reporter must not recursively break the global error handler.
      return false;
    }
  }

  void dispose() {
    if (_flutterHandler != null && identical(FlutterError.onError, _flutterHandler)) {
      FlutterError.onError = _previousFlutterHandler;
    }
    if (_platformHandler != null && identical(PlatformDispatcher.instance.onError, _platformHandler)) {
      PlatformDispatcher.instance.onError = _previousPlatformHandler;
    }
    _flutterHandler = null;
    _platformHandler = null;
  }
}
