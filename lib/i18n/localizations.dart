import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../base/base.dart';
import '../iso/iso.dart';
import 'app_translator.dart';
import 'l10n/l10n.dart';

class LocalizationsSdk {
  static LocalizationsSdk? _lastLoadedLocalizationsSdk;

  static LocalizationsSdk? get lastLoadedLocalizationsSdk => _lastLoadedLocalizationsSdk;

  static AppTranslator? _lastLoadedAppTranslator;

  static AppTranslator? get lastLoadedAppTranslator => _lastLoadedAppTranslator;

  static Completer? _loadingCompleter;

  static Locale get lastLoadedOrFallbackLocale => _lastLoadedLocalizationsSdk?.locale ?? firstDeviceOrFallbackLocale;

  static Locale get firstDeviceOrFallbackLocale => WidgetsBinding.instance.platformDispatcher.locale;

  final Locale locale;

  final String effectiveLocale;

  LocalizationsSdk(this.locale, this.effectiveLocale);

  DateFormat getLocaleDateFormatSafe(DateFormat Function(String) createFun, {String Function(Locale)? localeToStringFun}) {
    return createLocaleDateFormatSafe(createFun, forLocale: localeToStringFun == null ? locale.toString() : localeToStringFun(locale));
  }

  static DateFormat createLocaleDateFormatSafe(DateFormat Function(String) createFun, {required String forLocale}) {
    try {
      return createFun(forLocale);
    } on Object catch (_) {
      // falling back to 'en'
      return createFun('en');
    }
  }

  static Future<LocalizationsSdk> reloadOrGetCurrent(Locale locale) {
    assert(_lastLoadedLocalizationsSdk != null, 'Can\'t reload if nothing has been loaded yet');
    return load(locale);
  }

  static Future<LocalizationsSdk> load(Locale locale) async {
    var localeToLoad = locale;

    // determine the locale to use
    final localeName = Intl.canonicalizedLocale(localeToLoad.toString());
    final localTranslationSource = ArbAssetTranslationSource();
    final supportedLocales = await localTranslationSource.getSupportedLocales();
    var localeToUse = Intl.verifiedLocale(localeName, (locale) => supportedLocales.contains(locale), onFailure: (_) => null);
    if (localeToUse == null) {
      print('No translation found for locale $localeName. Falling back to "en"');
      localeToUse = '${IsoLanguageToString(IsoLanguage.English)}_${IsoCountryToString(IsoCountry.UnitedStates)}';
    }

    // get the currently active completer
    final completerToWaitFor = _loadingCompleter;

    if (_lastLoadedLocalizationsSdk != null && _lastLoadedLocalizationsSdk!.effectiveLocale == localeToUse) {
      print('LocalizationSDK: re-using already loaded instance ($localeToUse)');
      final result = _lastLoadedLocalizationsSdk!;
      if (completerToWaitFor != null) {
        await completerToWaitFor.future;
      }
      return result;
    }

    final completer = Completer();
    _loadingCompleter = completer;

    final result = LocalizationsSdk(localeToLoad, localeToUse);
    _lastLoadedLocalizationsSdk = result;

    if (completerToWaitFor != null) {
      await completerToWaitFor.future;
    }

    final appTranslator = AppTranslator(locale: localeToUse, translationSource: localTranslationSource);
    print('LocalizationSDK: loading Translations ($localeToUse)...');
    await appTranslator.load();
    print('LocalizationSDK: loading Translations ($localeToUse)...finished');

    _lastLoadedAppTranslator = appTranslator;

    TranslatorApiAccess.init(appTranslator);

    Intl.defaultLocale = localeToUse;

    print('LocalizationSDK: loading finished');

    completer.complete();
    return result;
  }

  static LocalizationsSdk of(BuildContext context) {
    final localizations = Localizations.of<LocalizationsSdk>(context, LocalizationsSdk);
    assert(localizations != null, "Could not find Localizations in context.");
    return localizations!;
  }
}
