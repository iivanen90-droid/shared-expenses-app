import 'package:core/src/constants/environment_type.dart';

final class AuthConfiguration {
  const AuthConfiguration({required this.url, required this.publishableKey, required this.environment});

  factory AuthConfiguration.fromDefines(EnvironmentType environment) => AuthConfiguration(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    environment: environment,
  );

  final String url;
  final String publishableKey;
  final EnvironmentType environment;

  bool get isEmpty => url.isEmpty && publishableKey.isEmpty;

  bool get isValid {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        (uri.path.isEmpty || uri.path == '/') &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        publishableKey.startsWith('sb_publishable_') &&
        publishableKey.trim() == publishableKey;
  }

  String get redirectUrl => 'sharedexpenses-${environment.name}://auth-callback';

  bool acceptsCallback(Uri uri) {
    if (uri.scheme != 'sharedexpenses-${environment.name}' ||
        uri.host != 'auth-callback' ||
        uri.path.isNotEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort) {
      return false;
    }
    if (uri.queryParameters.containsKey('code') || uri.queryParameters.containsKey('error')) return true;
    try {
      return Uri.splitQueryString(uri.fragment).containsKey('error');
    } on FormatException {
      return false;
    }
  }

  @override
  String toString() => 'AuthConfiguration(${environment.name})';
}
