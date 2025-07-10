import '../base/translator_api_access.dart';

class AppTranslatorUtils {
  static String get({String? key, String defaultEn = '', Map<String, Object>? args}) {
    if (key?.isEmpty ?? true) {
      return defaultEn;
    }
    return TranslatorApiAccess.instance.translator.translate(defaultEn: defaultEn, sid: key!, args: args);
  }
}
