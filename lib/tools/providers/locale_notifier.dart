import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LocaleNotifier extends Notifier<Locale> {
  static const _localeKey = 'locale';

  @override
  Locale build() {
    _loadLocale();
    return const Locale('fr', 'FR');
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey);
    if (localeCode != null) {
      state = Locale(localeCode);
    }
    // If no stored preference, keep the default 'fr_FR' (don't use Platform.localeName on web)
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  () => LocaleNotifier(),
);
