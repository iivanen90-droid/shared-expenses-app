import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

class _Service {}

class _Named {
  const _Named(this.name);
  final String name;
}

void main() {
  tearDown(DependencyProvider.reset);
  test('factories create new instances, singleton services preserve state', () {
    DependencyProvider.registerFactory<_Service>(_Service.new);
    expect(identical(DependencyProvider.get<_Service>(), DependencyProvider.get<_Service>()), isFalse);
    DependencyProvider.registerLazySingleton<StartupStatus>(StartupStatusImpl.new);
    DependencyProvider.get<StartupStatus>().markReady();
    expect(DependencyProvider.get<StartupStatus>().isReady, isTrue);
  });
  test('runtime parameters reach the requested factory', () {
    DependencyProvider.registerFactoryWithParams<_Named, String, void>((name, _) => _Named(name));
    expect(DependencyProvider.getWithParams<_Named>(param1: 'sample').name, 'sample');
    expect(DependencyProvider.getOrNull<_Service>(), isNull);
  });
}
