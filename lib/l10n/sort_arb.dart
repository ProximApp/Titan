import 'dart:convert';
import 'dart:io';

void main() async {
  final fileNames = ["app_en.arb", "app_fr.arb"];

  for (final fileName in fileNames) {
    final file = File("lib/l10n/$fileName");
    final content =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;

    final sortedKeys = content.keys.toList()
      ..sort((a, b) {
        final keyA =
            a.toLowerCase().replaceAll("@", "") +
            (a.startsWith("@") ? "a" : "");
        final keyB =
            b.toLowerCase().replaceAll("@", "") +
            (b.startsWith("@") ? "a" : "");
        return keyA.compareTo(keyB);
      });

    final sortedContent = {for (final key in sortedKeys) key: content[key]};

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(sortedContent),
    );
  }
}
