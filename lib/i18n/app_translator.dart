import '../base/base.dart';
import 'l10n/l10n.dart';

class AppTranslator implements Translator {
  static final String _fallbackLocale = 'en';

  final TranslationCache _translationCache;

  final TranslationSource translationSource;

  AppTranslator({required String locale, required this.translationSource})
    : _translationCache = TranslationCache(locale: locale, fallbackLocale: _getFallbackFor(locale), translationSource: translationSource);

  Future load() {
    return _translationCache.load();
  }

  void setGlobalReplacements(Map<String, String> globalReplacements) {
    _translationCache.setGlobalReplacements(globalReplacements);
  }

  @override
  String translate({required String defaultEn, required String sid, Map<String, Object>? args}) {
    return _translationCache.translate(sid, defaultEn, args: args);
  }

  @override
  String plural(int howMany, {required PluralStrings enStrings, required String sid, Map<String, Object>? args}) {
    return _translationCache.translatePlural(
      sid,
      howMany,
      defaultTextZero: enStrings.zero,
      defaultTextOne: enStrings.one,
      defaultTextTwo: enStrings.two,
      defaultTextFew: enStrings.few,
      defaultTextMany: enStrings.many,
      defaultTextOther: enStrings.other,
      args: args,
    );
  }

  static String? _getFallbackFor(String locale) {
    if (locale != _fallbackLocale) {
      return _fallbackLocale;
    }
    return null;
  }
}
