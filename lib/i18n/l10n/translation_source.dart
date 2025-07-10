import 'l10n.dart';

abstract class TranslationSource {
  Future<Map<String, Message>> loadTranslations(String locale);

  Future<List<String>> getSupportedLocales();
}
