import 'package:mocktail/mocktail.dart';
import 'package:titan/tools/logs/logger.dart';

/// The logger double every settings unit test overrides `loggerProvider`
/// with; three files declared this class identically.
class MockLogger extends Mock implements Logger {}
