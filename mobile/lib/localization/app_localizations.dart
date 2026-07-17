import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Loads localized strings from lib/localization/{locale}.json
/// and exposes a simple t(key, {params}) lookup.
///
/// Usage:
///   final t = AppLocalizations.of(context);
///   Text(t.t('authSendOtp'))
///   Text(t.t('authOtpResendIn', params: {'seconds': '30'}))
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;
  late Map<String, dynamic> _strings;

  static const supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  static AppLocalizations of(BuildContext context) {
    final instance =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(instance != null, 'No AppLocalizations found in context');
    return instance!;
  }

  Future<bool> load() async {
    final jsonString = await rootBundle.loadString(
      'lib/localization/${locale.languageCode}.json',
    );
    _strings = json.decode(jsonString) as Map<String, dynamic>;
    return true;
  }

  /// Looks up [key] and optionally substitutes {param} placeholders.
  /// Falls back to the key itself if missing, so untranslated strings
  /// are obvious during development instead of crashing.
  String t(String key, {Map<String, String>? params}) {
    var value = _strings[key] as String? ?? key;
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        value = value.replaceAll('{$paramKey}', paramValue);
      });
    }
    return value;
  }
}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi', 'mr'].contains(
        locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
