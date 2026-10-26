import 'dart:async';

import 'package:core/core.dart';
import 'package:core/src/preferences_storage/preferences_storage.dart' show PreferencesStorageImpl;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferencesAsyncPlatform? previousPlatform;
  late PreferencesStorage storage;

  setUp(() {
    previousPlatform = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    storage = PreferencesStorageImpl(preferences: SharedPreferencesAsync());
  });
  tearDown(() async {
    await DependencyProvider.reset();
    SharedPreferencesAsyncPlatform.instance = previousPlatform;
  });

  test('missing keys return null for all supported types', () async {
    expect(await storage.readBool(key: 'missing'), isNull);
    expect(await storage.readInt(key: 'missing'), isNull);
    expect(await storage.readString(key: 'missing'), isNull);
  });

  test('booleans round trip and can be overwritten with false', () async {
    await storage.writeBool(key: 'flag', value: true);
    expect(await storage.readBool(key: 'flag'), isTrue);
    await storage.writeBool(key: 'flag', value: false);
    expect(await storage.readBool(key: 'flag'), isFalse);
  });

  test('integers round trip including zero and negative values', () async {
    for (final value in [42, 0, -7]) {
      await storage.writeInt(key: 'number', value: value);
      expect(await storage.readInt(key: 'number'), value);
    }
  });

  test('strings round trip including Unicode and the empty string', () async {
    for (final value in ['Українська 🌻', '']) {
      await storage.writeString(key: 'text', value: value);
      expect(await storage.readString(key: 'text'), value);
    }
  });

  for (final key in ['flag', 'number', 'text']) {
    test('remove deletes only the selected $key entry', () async {
      await storage.writeBool(key: 'flag', value: true);
      await storage.writeInt(key: 'number', value: 17);
      await storage.writeString(key: 'text', value: 'kept');
      await storage.remove(key: key);
      expect(await storage.readBool(key: 'flag'), key == 'flag' ? isNull : isTrue);
      expect(await storage.readInt(key: 'number'), key == 'number' ? isNull : 17);
      expect(await storage.readString(key: 'text'), key == 'text' ? isNull : 'kept');
    });
  }

  test('removing a missing key succeeds without changing other entries', () async {
    await storage.writeString(key: 'kept', value: 'value');
    await storage.remove(key: 'missing');
    expect(await storage.readString(key: 'kept'), 'value');
  });

  test('type mismatches surface instead of silently returning defaults', () async {
    await storage.writeString(key: 'text', value: 'value');
    await storage.writeBool(key: 'flag', value: true);
    await expectLater(storage.readBool(key: 'text'), throwsA(isA<TypeError>()));
    await expectLater(storage.readInt(key: 'text'), throwsA(isA<TypeError>()));
    await expectLater(storage.readString(key: 'flag'), throwsA(isA<TypeError>()));
  });

  test('platform read, write and remove errors reach the caller', () async {
    SharedPreferencesAsyncPlatform.instance = _FailingPlatform();
    final failing = PreferencesStorageImpl(preferences: SharedPreferencesAsync());
    await expectLater(failing.readString(key: 'key'), throwsA(isA<PlatformException>()));
    await expectLater(failing.writeString(key: 'key', value: 'value'), throwsA(isA<PlatformException>()));
    await expectLater(failing.remove(key: 'key'), throwsA(isA<PlatformException>()));
  });

  test('write completes only after the platform operation completes', () async {
    final platform = _DelayedPlatform();
    SharedPreferencesAsyncPlatform.instance = platform;
    final delayed = PreferencesStorageImpl(preferences: SharedPreferencesAsync());
    var completed = false;
    final write = delayed.writeBool(key: 'flag', value: true).then((_) => completed = true);
    try {
      await platform.started.future;
      expect(completed, isFalse);
      expect(await delayed.readBool(key: 'flag'), isNull);
    } finally {
      platform.release.complete();
      await write;
    }
    expect(await delayed.readBool(key: 'flag'), isTrue);
  });

  test('remove completes only after the platform operation completes', () async {
    final platform = _DelayedPlatform();
    SharedPreferencesAsyncPlatform.instance = platform;
    final delayed = PreferencesStorageImpl(preferences: SharedPreferencesAsync());
    await delayed.writeString(key: 'text', value: 'value');
    var completed = false;
    final remove = delayed.remove(key: 'text').then((_) => completed = true);
    try {
      await platform.started.future;
      expect(completed, isFalse);
      expect(await delayed.readString(key: 'text'), 'value');
    } finally {
      platform.release.complete();
      await remove;
    }
    expect(await delayed.readString(key: 'text'), isNull);
  });

  test('core resolver registers storage lazily and returns one shared instance', () async {
    SharedPreferencesAsyncPlatform.instance = null;
    CoreDependenciesModuleResolver.register(environment: EnvironmentType.dev);
    expect(DependencyProvider.isRegistered<PreferencesStorage>(), isTrue);
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final first = DependencyProvider.get<PreferencesStorage>();
    final second = DependencyProvider.get<PreferencesStorage>();
    expect(second, same(first));
    await first.writeInt(key: 'shared', value: 7);
    expect(await second.readInt(key: 'shared'), 7);
  });
}

final class _FailingPlatform extends InMemorySharedPreferencesAsync {
  _FailingPlatform() : super.empty();
  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) async =>
      throw PlatformException(code: 'storage_unavailable');
  @override
  Future<bool> setString(String key, String value, SharedPreferencesOptions options) async =>
      throw PlatformException(code: 'storage_unavailable');
  @override
  Future<bool> clear(ClearPreferencesParameters parameters, SharedPreferencesOptions options) async =>
      throw PlatformException(code: 'storage_unavailable');
}

final class _DelayedPlatform extends InMemorySharedPreferencesAsync {
  _DelayedPlatform() : super.empty();
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<bool> setBool(String key, bool value, SharedPreferencesOptions options) async {
    started.complete();
    await release.future;
    return super.setBool(key, value, options);
  }

  @override
  Future<bool> clear(ClearPreferencesParameters parameters, SharedPreferencesOptions options) async {
    started.complete();
    await release.future;
    return super.clear(parameters, options);
  }
}
