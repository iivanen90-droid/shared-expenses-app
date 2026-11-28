import 'package:core/core.dart';
import 'package:core/src/auth/supabase_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const configuration = AuthConfiguration(
    url: 'https://example.supabase.co',
    publishableKey: 'sb_publishable_test',
    environment: EnvironmentType.dev,
  );

  test('accepts only public publishable configuration and hides its contents', () {
    expect(configuration.isValid, isTrue);
    expect(configuration.toString(), 'AuthConfiguration(dev)');
    for (final key in ['sb_secret_private', 'service_role', 'sb_publishable_test ']) {
      expect(
        AuthConfiguration(url: configuration.url, publishableKey: key, environment: EnvironmentType.dev).isValid,
        isFalse,
      );
    }
  });

  test('rejects credentials, query strings, paths and insecure project URLs', () {
    for (final url in [
      'http://example.supabase.co',
      'https://user:password@example.supabase.co',
      'https://example.supabase.co/auth',
      'https://example.supabase.co?key=secret',
    ]) {
      expect(
        AuthConfiguration(
          url: url,
          publishableKey: configuration.publishableKey,
          environment: EnvironmentType.dev,
        ).isValid,
        isFalse,
      );
    }
  });

  test('callback is restricted to the selected flavor and exact host', () {
    expect(configuration.redirectUrl, 'sharedexpenses-dev://auth-callback');
    expect(configuration.acceptsCallback(Uri.parse('${configuration.redirectUrl}?code=test')), isTrue);
    expect(configuration.acceptsCallback(Uri.parse('${configuration.redirectUrl}?error=access_denied')), isTrue);
    expect(configuration.acceptsCallback(Uri.parse('${configuration.redirectUrl}#error=access_denied')), isTrue);
    for (final url in [
      'sharedexpenses-prod://auth-callback?code=test',
      'sharedexpenses-dev://other?code=test',
      'sharedexpenses-dev://auth-callback/path?code=test',
      'sharedexpenses-dev://auth-callback',
      'sharedexpenses-dev://auth-callback#access_token=test',
    ]) {
      expect(configuration.acceptsCallback(Uri.parse(url)), isFalse);
    }
  });

  test('empty configuration preserves local startup without loading plugins', () async {
    final service = SupabaseAuthService(
      configuration: const AuthConfiguration(url: '', publishableKey: '', environment: EnvironmentType.dev),
    );
    await Future.wait([service.initialize(), service.initialize()]);
    expect(service.sessionSource.current.session, AuthenticationStatus.unconfigured);
    expect((await service.launchSignIn(source: AuthSource.google)).isLeft(), isTrue);
    await service.dispose();
  });

  test('invalid configuration produces a safe failure without initializing Supabase', () async {
    final service = SupabaseAuthService(
      configuration: const AuthConfiguration(
        url: 'https://example.supabase.co',
        publishableKey: 'sb_secret_private',
        environment: EnvironmentType.dev,
      ),
    );
    await service.initialize();
    expect(service.sessionSource.current.failure?.kind, AuthenticationFailureKind.configuration);
    await service.dispose();
  });
}
