import 'package:flutter/services.dart' show appFlavor;

enum EnvironmentType {
  dev,
  prod;

  bool get isDebug => this == dev;

  static EnvironmentType fromDefines() {
    const configured = String.fromEnvironment('ENVIRONMENT');
    final value = configured.isEmpty ? (appFlavor ?? 'dev') : configured;
    if (appFlavor != null && value != appFlavor) {
      throw ArgumentError('ENVIRONMENT must match the native flavor.');
    }
    return switch (value) {
      'dev' => dev,
      'prod' => prod,
      _ => throw ArgumentError('ENVIRONMENT must be dev or prod.'),
    };
  }
}
