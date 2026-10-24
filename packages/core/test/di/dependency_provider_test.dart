import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

class _Service {}

class _ConfiguredService {
  const _ConfiguredService({required this.name, required this.index});
  final String name;
  final int index;
}

void main() {
  tearDown(DependencyProvider.reset);

  test('a factory returns a new service on every lookup', () {
    DependencyProvider.registerFactory<_Service>(_Service.new);
    expect(DependencyProvider.get<_Service>(), isNot(same(DependencyProvider.get<_Service>())));
  });

  test('a lazy singleton is created once and only when requested', () {
    var creations = 0;
    DependencyProvider.registerLazySingleton<_Service>(() {
      creations++;
      return _Service();
    });
    expect(creations, 0);
    final service = DependencyProvider.get<_Service>();
    expect(DependencyProvider.get<_Service>(), same(service));
    expect(creations, 1);
  });

  test('a parameterized factory receives both values on each lookup', () {
    DependencyProvider.registerFactoryWithParams<_ConfiguredService, String, int>(
      (name, index) => _ConfiguredService(name: name, index: index),
    );
    final first = DependencyProvider.getWithParams<_ConfiguredService>(param1: 'first', param2: 1);
    final second = DependencyProvider.getWithParams<_ConfiguredService>(param1: 'second', param2: 2);
    expect(first.name, 'first');
    expect(first.index, 1);
    expect(second.name, 'second');
    expect(second.index, 2);
    expect(second, isNot(same(first)));
  });

  test('optional lookup returns null only when the service is not registered', () {
    expect(DependencyProvider.isRegistered<_Service>(), isFalse);
    expect(DependencyProvider.getOrNull<_Service>(), isNull);
    final service = _Service();
    DependencyProvider.registerLazySingleton<_Service>(() => service);
    expect(DependencyProvider.isRegistered<_Service>(), isTrue);
    expect(DependencyProvider.getOrNull<_Service>(), same(service));
  });

  test('optional lookup does not hide errors from a registered factory', () {
    final error = StateError('Factory failed');
    DependencyProvider.registerFactory<_Service>(() => throw error);
    expect(DependencyProvider.getOrNull<_Service>, throwsA(same(error)));
  });

  test('reset removes factory and lazy singleton registrations', () async {
    DependencyProvider.registerFactory<_Service>(_Service.new);
    DependencyProvider.registerLazySingleton<_ConfiguredService>(
      () => const _ConfiguredService(name: 'singleton', index: 0),
    );
    await DependencyProvider.reset();
    expect(DependencyProvider.isRegistered<_Service>(), isFalse);
    expect(DependencyProvider.isRegistered<_ConfiguredService>(), isFalse);
    expect(DependencyProvider.getOrNull<_Service>(), isNull);
  });

  test('reset awaits asynchronous disposal of the instantiated singleton', () async {
    final disposalStarted = Completer<void>();
    final allowDisposal = Completer<void>();
    final service = _Service();
    _Service? disposedService;
    var resetCompleted = false;
    DependencyProvider.registerLazySingleton<_Service>(
      () => service,
      dispose: (instance) async {
        disposedService = instance;
        disposalStarted.complete();
        await allowDisposal.future;
      },
    );
    expect(DependencyProvider.get<_Service>(), same(service));
    final reset = DependencyProvider.reset().then((_) => resetCompleted = true);
    try {
      await disposalStarted.future;
      expect(disposedService, same(service));
      expect(resetCompleted, isFalse);
    } finally {
      allowDisposal.complete();
      await reset;
    }
    expect(resetCompleted, isTrue);
    expect(DependencyProvider.isRegistered<_Service>(), isFalse);
  });

  test('reset does not instantiate an unused lazy singleton for disposal', () async {
    var creations = 0;
    var disposals = 0;
    DependencyProvider.registerLazySingleton<_Service>(() {
      creations++;
      return _Service();
    }, dispose: (_) => disposals++);
    await DependencyProvider.reset();
    expect(creations, 0);
    expect(disposals, 0);
    expect(DependencyProvider.isRegistered<_Service>(), isFalse);
  });
}
