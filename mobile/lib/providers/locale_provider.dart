import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_prefs_service.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._prefs, Locale initial) : super(initial);

  final LocalPrefsService _prefs;

  void setLocale(Locale locale) {
    state = locale;
    // Fire-and-forget: persist so the choice survives a hot restart
    // or the app being closed and reopened later.
    _prefs.saveLocale(locale.languageCode);
  }
}

final _localPrefsProvider = Provider((ref) => LocalPrefsService());

/// Seeded with whatever locale was loaded at app bootstrap (see
/// main.dart) — defaults to Marathi if nothing was ever saved, since
/// that's the most likely first language for our pilot shops.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(ref.watch(_localPrefsProvider), const Locale('mr')),
);

