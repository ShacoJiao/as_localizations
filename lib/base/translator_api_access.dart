import 'translator.dart';

class TranslatorApiAccess {
  final Translator _translator;

  TranslatorApiAccess._({required Translator translator}) : _translator = translator;

  static TranslatorApiAccess? _instance;

  static TranslatorApiAccess get instance {
    assert(_instance != null, 'TranslatorApiAccess not yet initialized!');
    return _instance!;
  }

  static void init(Translator translator) {
    _instance = TranslatorApiAccess._(translator: translator);
  }

  Translator get translator => _translator;
}
