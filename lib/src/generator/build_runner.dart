import 'dart:async';
import 'package:build_runner/build_runner.dart';
import 'package:jaguar_http_cli/src/generator/generator.dart';
import 'package:jaguar_serializer_cli/src/config/config.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build_runner/build_runner.dart' as build_runner;

class JaguarHttpConfig extends JaguarSerializerConfig {
  static const String httpKey = 'jaguar_http';

  JaguarHttpConfig({String configFileName: "pubspec.yaml"})
      : super(configFileName: configFileName);

  List<String> get httpFiles => config[httpKey];
}

String get _usage => '''
Available commands:
  - build
  - watch
''';

start(List<String> args) {
  if (args.length > 0) {
    if (args[0] == 'watch') {
      return watch();
    } else if (args[0] == 'build') {
      return build();
    }
  }
  print(_usage);
}

Phase apisPhase(String projectName, List<String> apis) {
  return new Phase()
    ..addAction(
        new GeneratorBuilder(const [
          const JaguarHttpGenerator(),
        ]),
        new InputSet(projectName, apis));
}

PhaseGroup generatePhaseGroup({String projectName, List<String> apis}) {
  final phaseGroup = new PhaseGroup();
  phaseGroup.addPhase(apisPhase(projectName, apis));
  return phaseGroup;
}

PhaseGroup phaseGroup({String configFileName: jaguarSerializerConfigFile}) {
  final defaultPath = [
    "lib/**/**.dart",
    "bin/**/**.dart",
    "test/**/**.dart",
    "example/**/**.dart",
    "lib/*.dart",
    "bin/*.dart",
    "test/*.dart",
    "example/*.dart"
  ];
  final config = new JaguarHttpConfig();

  if (config.pubspec.projectName == null) {
    throw "Could not find the project name";
  }

  var httpFiles = config.httpFiles;

  if (httpFiles == null || httpFiles.isEmpty) {
    print(
        "[WARNING] Jaguar Http did not find any files to watch in 'pubspec.yaml', '$defaultPath' used by default");
    httpFiles = defaultPath;
  }

  return generatePhaseGroup(
      projectName: config.pubspec.projectName, apis: httpFiles);
}

/// Watch files and trigger build function
Stream<build_runner.BuildResult> watch() =>
    build_runner.watch(phaseGroup(), deleteFilesByDefault: true);

/// Build all Http Class
Future<build_runner.BuildResult> build() =>
    build_runner.build(phaseGroup(), deleteFilesByDefault: true);
