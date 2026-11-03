import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/recurrence.dart';

void main() {
  group('Testing AppException class', () {
    test('Should return an AppException', () {
      final AppException exception = AppException(
        ErrorType.tokenExpire,
        "Token Expired",
      );
      expect(exception, isA<AppException>());
      expect(exception.type, ErrorType.tokenExpire);
      expect(exception.message, "Token Expired");
    });

    test('Should return a string', () {
      final AppException exception = AppException(
        ErrorType.tokenExpire,
        "Token Expired",
      );
      expect(exception.toString(), "tokenExpire : Token Expired");
    });
    test('Should return an ErrorType', () {
      expect(ErrorType.tokenExpire, isA<ErrorType>());
      expect(ErrorType.notFound, isA<ErrorType>());
      expect(ErrorType.invalidData, isA<ErrorType>());
    });
  });

  group('Testing capitalize function', () {
    test('Should return a string', () {
      expect(capitalize("test"), isA<String>());
    });

    test('Should return a capitalized string', () {
      expect(capitalize("test"), "Test");
      expect(capitalize("TEST"), "Test");
    });

    test('Should return an empty string', () {
      expect(capitalize(""), "");
    });

    test('Should capitalize only the first word', () {
      expect(capitalize("test a"), "Test a");
    });
  });

  group('Testing capitaliseAll function', () {
    test('Should return a string', () {
      expect(capitaliseAll("test"), isA<String>());
    });

    test('Should return a capitalized string', () {
      expect(capitaliseAll("test"), "Test");
      expect(capitaliseAll("TEST"), "Test");
      expect(capitaliseAll("test a"), "Test A");
      expect(capitaliseAll("test-a"), "Test-A");
      expect(capitaliseAll("test_a"), "Test_A");
    });

    test('Should return an empty string', () {
      expect(capitaliseAll(""), "");
    });
  });

  group('Testing processDatePrint function', () {
    test('Should return a string', () {
      const date = "2021-1-1";
      expect(processDatePrint(""), "");
      expect(processDatePrint(date), isA<String>());
      expect(processDatePrint(date), "01/01/2021");
    });
  });

  group('Testing processDateBack function', () {});

  test('Testing getDateInRecurrence', () {
    const recurrenceRule =
        "FREQ=WEEKLY;BYDAY=MO;WKST=MO;INTERVAL=1;UNTIL=20210115T235959Z";
    const recurrenceRule2 = "";
    final date = DateTime.parse("2021-01-01T00:00:00.000Z");
    expect(getDateInRecurrence(recurrenceRule, date), [
      DateTime.parse("2021-01-04T00:00:00.000"),
      DateTime.parse("2021-01-11T00:00:00.000"),
    ]);
    expect(getDateInRecurrence(recurrenceRule2, date), []);
  });

  test('Testing normalzedDate', () {
    final date = DateTime.parse("2021-01-01T00:00:00.000Z");
    final date2 = DateTime.parse("2021-01-01T01:00:00.000Z");
    expect(normalizedDate(date), DateTime.parse("2021-01-01T00:00:00.000"));
    expect(normalizedDate(date2), DateTime.parse("2021-01-01T00:00:00.000"));
  });

  group('Testing processDateToAPI', () {
    test('Should return a string', () {
      final date = DateTime.parse("2021-01-01");
      expect(processDateToAPI(date), isA<String>());
      expect(processDateToAPI(date), date.toUtc().toIso8601String());
    });
  });
}
