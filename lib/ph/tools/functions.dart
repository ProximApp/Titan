import 'package:intl/intl.dart';

String phFormatDate(DateTime date, String locale) {
  final DateFormat formatter = DateFormat.yMMMMd(locale);
  return formatter.format(date);
}

String phFormatDateEntry(DateTime date, String locale) {
  final DateFormat formatter = DateFormat.yMMMd(locale);
  return formatter.format(date);
}

String shortenText(String text, int maxLength) {
  if (text.length <= maxLength) {
    return text;
  } else {
    return '${text.substring(0, maxLength - 3)}...';
  }
}

/// Parses the date entry's text of the add/edit page back to a [DateTime].
///
/// The field PREFILLS with the pretty `yMMMd` format ('Jan 1, 2000') while
/// getOnlyDayDate writes back the `yMd` format ('1/1/2000'), while
/// processDateBack only understands the latter — submitting an untouched
/// prefill used to throw a FormatException before the paper was ever sent.
/// Both shapes are accepted here.
DateTime phParseDateEntry(String text, String locale) {
  try {
    return DateFormat.yMd(locale).parse(text);
  } on FormatException {
    return DateFormat.yMMMd(locale).parse(text);
  }
}
