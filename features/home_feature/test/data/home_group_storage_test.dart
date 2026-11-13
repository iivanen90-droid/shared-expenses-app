import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_feature/objectbox.g.dart';
import 'package:home_feature/src/data/mapper/home_group_mapper.dart';
import 'package:home_feature/src/data/repository/home_groups_repository_impl.dart';
import 'package:home_feature/src/data/source/home_groups_source.dart';

void main() {
  test(
    'ObjectBox persists a group and participant names across store reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp('tricount-groups-test-');
      BoxHomeGroupsSource source() =>
          BoxHomeGroupsSource(storeOpener: () => Store(getObjectBoxModel(), directory: directory.path));
      final writer = source();
      final reader = source();
      try {
        final repository = HomeGroupsRepositoryImpl(source: writer, mapper: const HomeGroupMapper());
        final result = await repository.create((
          name: 'City trip',
          emoji: '🏕️',
          currencyCode: 'UAH',
          participants: ['Alex', 'Sam'],
        ));
        final created = result.getOrElse((_) => throw StateError('Write failed'));
        expect(created.id, greaterThan(0));
        await writer.close();

        final reopened = HomeGroupsRepositoryImpl(source: reader, mapper: const HomeGroupMapper());
        final groups = (await reopened.watchGroups().first).getOrElse((_) => throw StateError('Read failed'));
        final group = groups.single;
        expect(group.id, created.id);
        expect(group.name, 'City trip');
        expect(group.emoji, '🏕️');
        expect(group.currencyCode, 'UAH');
        expect(group.participants, ['Alex', 'Sam']);
        final found = (await reopened.getGroupById(group.id)).getOrElse((_) => throw StateError('Lookup failed'));
        expect(found?.name, 'City trip');
        expect(
          (await reopened.getGroupById(group.id + 100)).getOrElse((_) => throw StateError('Lookup failed')),
          isNull,
        );
      } finally {
        await writer.close();
        await reader.close();
        Store.removeDbFiles(directory.path);
        await directory.delete();
      }
    },
    skip: Platform.environment['TRICOUNT_TEST_OBJECTBOX'] != '1'
        ? 'Set TRICOUNT_TEST_OBJECTBOX=1 and provide the native ObjectBox library.'
        : false,
  );
}
