import 'dart:io';

final root = File.fromUri(Platform.script).parent.parent;
final sdk = Platform.environment['TRICOUNT_FLUTTER_SDK'];
final members = RegExp(r'^  - ([a-z_/]+)$', multiLine: true)
    .allMatches(File('${root.path}/pubspec.yaml').readAsStringSync())
    .map((match) => match.group(1))
    .whereType<String>()
    .toList();

Future<void> command(String tool, List<String> arguments, {String? package}) async {
  final String executable;
  final List<String> args;
  if (sdk == null) {
    executable = 'fvm';
    args = [tool, ...arguments];
  } else {
    final suffix = Platform.isWindows ? '.bat' : '';
    executable = '$sdk/bin/$tool$suffix';
    args = arguments;
  }
  final process = await Process.start(
    executable,
    args,
    workingDirectory: package == null ? root.path : '${root.path}/$package',
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  final result = await process.exitCode;
  if (result != 0) exit(result);
}

void normalizeGeneratedFiles() {
  // Freezed disables dart format and can emit trailing whitespace; normalize generator output reproducibly.
  for (final member in members) {
    final lib = Directory('${root.path}/$member/lib');
    if (!lib.existsSync()) continue;
    for (final file in lib.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.freezed.dart') && !file.path.endsWith('.g.dart')) continue;
      final original = file.readAsStringSync();
      final normalized = original.replaceAll('\r\n', '\n').replaceAll(RegExp(r'[ \t]+$', multiLine: true), '');
      if (original != normalized) file.writeAsStringSync(normalized);
    }
  }
}

Future<void> tests() async {
  for (final member in members) {
    final folder = Directory('${root.path}/$member/test');
    if (folder.existsSync() &&
        folder.listSync(recursive: true).whereType<File>().any((f) => f.path.endsWith('_test.dart'))) {
      await command('flutter', ['test', '--no-pub'], package: member);
    }
  }
}

Future<void> main(List<String> args) async {
  final task = args.isEmpty ? 'check' : args.single;
  switch (task) {
    case 'get':
      await command('flutter', ['pub', 'get']);
    case 'generate':
      await command('dart', [
        'run',
        'easy_localization:generate',
        '-S',
        'lib/src/localization/langs',
        '-O',
        'lib/src/localization',
        '-f',
        'keys',
        '-o',
        'locale_keys.g.dart',
      ], package: 'packages/common');
      for (final member in members) {
        if (File('${root.path}/$member/pubspec.yaml').readAsStringSync().contains('  build_runner:')) {
          await command('dart', ['run', 'build_runner', 'build', '--force-jit'], package: member);
        }
      }
      normalizeGeneratedFiles();
      await command('dart', ['format', 'mobile', 'packages', 'features', 'tools']);
    case 'format':
      normalizeGeneratedFiles();
      await command('dart', ['format', 'mobile', 'packages', 'features', 'tools']);
    case 'test':
      await tests();
    case 'analyze':
      await command('flutter', ['analyze', '--no-pub', '--fatal-infos', '--fatal-warnings']);
    case 'check':
      await command('flutter', ['pub', 'get', '--enforce-lockfile']);
      await command('dart', [
        'format',
        '--output=none',
        '--set-exit-if-changed',
        'mobile',
        'packages',
        'features',
        'tools',
      ]);
      await command('flutter', ['analyze', '--no-pub', '--fatal-infos', '--fatal-warnings']);
      await tests();
    default:
      stderr.writeln('Usage: fvm dart tools/workspace.dart [get|generate|format|test|analyze|check]');
      exitCode = 64;
  }
}
