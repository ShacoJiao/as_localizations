import 'dart:convert';

import '../l10n.dart';

/// Translation source that provides the translations stored in ARB files in the assets
class ArbAssetTranslationSource implements TranslationSource {
  static final String _arbListFileName = 'intl_list.txt';
  final _jsonDecoder = const JsonCodec();

  List<String>? _supportedLocales;

  ArbAssetTranslationSource();

  @override
  Future<Map<String, Message>> loadTranslations(String locale) async {
    if (!(await getSupportedLocales()).contains(locale)) {
      return {};
    }
    String plainArbJson;
    try {
      plainArbJson = await AssetLoadHelper.loadAsset(_getArbAssetFilenameForLocale(locale));
    } catch (e) {
      rethrow;
    }
    final Map<String, dynamic> arbJsonDom = _jsonDecoder.decode(plainArbJson);
    return _loadTranslationsFromJsonDom(arbJsonDom);
  }

  @override
  Future<List<String>> getSupportedLocales() async {
    if (_supportedLocales == null) {
      final localesListString = await AssetLoadHelper.loadAsset(_arbListFileName);
      _supportedLocales = localesListString.split('\n').where((locale) => locale.trim().isNotEmpty).toList(growable: false);
    }
    return _supportedLocales!;
  }

  Map<String, Message> _loadTranslationsFromJsonDom(Map<String, dynamic> jsonDom) {
    final result = <String, Message>{};
    // the parser is stateless => only create it once
    final parser = IcuParser();
    for (final translationKey in jsonDom.keys) {
      if (jsonDom[translationKey] is String) {
        if (translationKey.startsWith('@@')) {
          // we skip ARB metadata
          continue;
        }
        // this parses the translation into a [Message] tree
        final parseResult = parser.anyMessage.parse(jsonDom[translationKey] as String);
        final parsedArbResourceValue = parseResult.value;

        result[translationKey] = parsedArbResourceValue;
      } else {
        print('Unsupported datatype for translation keys: ${jsonDom[translationKey].runtimeType.toString()} (Key="$translationKey")');
      }
    }
    return result;
  }

  static String _getArbAssetFilenameForLocale(String locale) {
    return 'intl_$locale.arb';
  }
}
