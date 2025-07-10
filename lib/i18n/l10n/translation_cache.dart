import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'l10n.dart';

class TranslationCache {
  /// fallback locale that is used if [locale] has no translation result
  final String? fallbackLocale;

  /// locale to use (e.g. for plural logic)
  final String locale;

  _LoadingState _loadingState = _LoadingState.notLoaded;
  final Map<String, _TranslationCacheEntry> _translationsCache = {};

  final TranslationSource translationSource;

  Map<String, String> _globalReplacements = {};

  Map<String, String> _getGlobalReplacements() => _globalReplacements;

  /// creates a new [TranslationCache].
  /// In order to use it [load] has to be called
  TranslationCache({required this.locale, required this.fallbackLocale, required this.translationSource});

  /// loads the translations using [arbFileAssetKey]
  Future load() async {
    if (_loadingState != _LoadingState.notLoaded) {
      return;
    }
    _loadingState = _LoadingState.loading;
    await _initCache();
    _loadingState = _LoadingState.loaded;
  }

  /// allows to set global variable replacements.
  /// Those replacements get used even if the translation request doesn't contain those variables.
  /// This method also tries to pre-translate all Strings that only contain variables defined in [globalReplacements] so that the result can
  /// be cached
  void setGlobalReplacements(Map<String, String> globalReplacements) {
    _globalReplacements = {};
    for (final globalReplacementKey in globalReplacements.keys) {
      _globalReplacements[globalReplacementKey.toUpperCase()] = globalReplacements[globalReplacementKey]!;
    }
    for (final entry in _translationsCache.values) {
      entry.preTranslateIfPossible();
    }
  }

  String translate(String? name, String defaultText, {Map<String, Object>? args}) {
    assert(_loadingState == _LoadingState.loaded, 'TranslationCache not yet loaded its data => can\'t deliver translations');
    if (name == null) {
      if (kDebugMode) print('Requested a translation with name == null!');
      return defaultText;
    }
    // get the cache entry
    final entry = _translationsCache[name];
    if (entry == null) {
      // no translation found for SID [name] => log error and return default text
      if (kDebugMode) print('No translation for SID "$name"!');
      return defaultText;
    }
    return entry.getTranslation(args: _toStringMap(args));
  }

  String translatePlural(
    String? name,
    int howMany, {
    String? defaultTextZero,
    String? defaultTextOne,
    String? defaultTextTwo,
    String? defaultTextFew,
    String? defaultTextMany,
    required String defaultTextOther,
    Map<String, Object>? args,
  }) {
    assert(_loadingState == _LoadingState.loaded, 'TranslationCache not yet loaded its data => can\'t deliver translations');
    if (name == null) {
      if (kDebugMode) print('Requested a translation with name == null!');
      return defaultTextOther;
    }
    // get the cache entry
    final entry = _translationsCache[name];
    if (entry == null) {
      if (kDebugMode) print('No translation for SID "$name"!');
      return Intl.pluralLogic<String>(
        howMany,
        zero: defaultTextZero,
        one: defaultTextOne,
        two: defaultTextTwo,
        few: defaultTextFew,
        many: defaultTextMany,
        other: defaultTextOther,
        locale: locale,
      );
    }
    return entry.getTranslation(args: _toStringMap(args));
  }

  static Map<String, String> _toStringMap(Map<String, Object>? sourceMap) {
    final result = <String, String>{};
    if (sourceMap != null) {
      for (final key in sourceMap.keys) {
        result[key] = sourceMap[key]!.toString();
      }
    }
    return result;
  }

  Future _initCache() async {
    _translationsCache.clear();
    await _fillCacheFromTranslationSource();
  }

  Future _fillCacheFromTranslationSource() async {
    // if we have a fallback available then we populate the cache with all translations from the fallback locale
    // those values will be overwritten by the locale translations if they are available
    if (fallbackLocale != null) {
      await _fillCacheForLocale(fallbackLocale!, isFallback: true);
    }
    await _fillCacheForLocale(locale);
  }

  Future _fillCacheForLocale(String locale, {bool isFallback = false}) async {
    final translations = await translationSource.loadTranslations(locale);
    for (final translationKey in translations.keys) {
      if (_translationsCache.containsKey(translationKey)) {
        // if we encounter a fallback value in the cache then this is expected and we don't have to warn
        if (!_translationsCache[translationKey]!.isFallback) {
          if (kDebugMode) {
            print('''
            Translation for $translationKey is defined multiple times!, extras: {
            'translationKey': $translationKey,
              'translationSource': ${translationSource.toString()},
              }
            ''');
          }
        }
      }
      _translationsCache[translationKey] = _TranslationCacheEntry.fromMessage(
        translationKey,
        locale,
        translations[translationKey]!,
        _getGlobalReplacements,
        isFallback: isFallback,
      );
    }
  }
}

typedef GetGlobalReplacements = Map<String, String> Function();

/// this represents a cache entry for one translation.
/// If possible the cache entry will translate immediately and store the result.
/// If not possible (e.g. if variables have to be provided) the translation happens on demand.
class _TranslationCacheEntry {
  // the [Message] tree representing this translation
  final Message _message;

  final GetGlobalReplacements _getGlobalReplacements;

  // pre-translated String. this is used if existent before doing on demand translation
  String? _translated;

  // list of variable names this translation expects
  List<String> _variableNames = const [];

  /// locale provided by [MessageLookupDynamic]. Used for plural logic
  final String locale;

  /// for reference: the name this translation entry has
  final String name;

  /// marks an entry as fallback to not trigger an overwrite warning
  final bool isFallback;

  void preTranslateIfPossible() {
    final globalReplacements = _getGlobalReplacements();
    // if we don't have any variables or replacements, we have nothing to do
    if (_variableNames.isEmpty || globalReplacements.isEmpty) {
      return;
    }
    // we only can pre-translate if all of our variables are global replacements
    bool onlyGlobalReplacements = _variableNames.every((variableName) => globalReplacements.containsKey(variableName));
    if (onlyGlobalReplacements) {
      final translateVisitor = MessageResolveVisitor();
      var translateContext = _MessageResolveTranslationContext(name: name, locale: locale, variableReplacements: globalReplacements);
      _message.accept(translateVisitor, translateContext);
      _translated = translateContext.translationResult.toString();
    }
  }

  _TranslationCacheEntry.fromMessage(this.name, this.locale, Message message, GetGlobalReplacements getGlobalReplacements, {required this.isFallback})
    : _message = message,
      _getGlobalReplacements = getGlobalReplacements {
    // 1. do an analysis run
    final analyzeVisitor = MessageResolveVisitor();
    var analyzeContext = _MessageResolveAnalysisContext(name: name, locale: locale);
    message.accept(analyzeVisitor, analyzeContext);
    // if this is a simple message...
    if (analyzeContext.isSimpleText) {
      // ... then do the translation immediately and store the result
      final translateVisitor = MessageResolveVisitor();
      var translateContext = _MessageResolveTranslationContext(name: name, locale: locale);
      message.accept(translateVisitor, translateContext);
      _translated = translateContext.translationResult.toString();
    } else {
      _variableNames = analyzeContext.variableNames;
    }
  }

  /// returns a translated String for the given [args]
  String getTranslation({Map<String, String> args = const {}}) {
    // if we have a pre-translated String already, just return that
    // if there are any args we have to dig deeper... (we might face a local override)
    if (_translated != null && args.isEmpty) {
      return _translated!;
    }
    final argsUpperCase = {};
    for (final argsKey in args.keys) {
      argsUpperCase[argsKey.toUpperCase()] = args[argsKey];
    }
    // Initiate a translation run. As the [Message] tree can be quite complex & nested we have to use a visitor
    final translateVisitor = MessageResolveVisitor();

    final globalReplacements = _getGlobalReplacements();

    // merge local variables with global replacements
    var variableReplacements = <String, String>{...argsUpperCase};

    bool isLocalOverride = false;
    for (final globalReplacementVar in globalReplacements.keys) {
      // allow local overrides => check if already set
      if (!variableReplacements.containsKey(globalReplacementVar)) {
        variableReplacements[globalReplacementVar] = globalReplacements[globalReplacementVar]!;
      } else {
        isLocalOverride = isLocalOverride || variableReplacements[globalReplacementVar] != globalReplacements[globalReplacementVar];
      }
    }
    // if we have a pre-translated text and no given variable value differs then we can return the already translated String
    if (!isLocalOverride && _translated != null) {
      return _translated!;
    }
    var missingVariables = [];
    for (final expectedVar in _variableNames) {
      if (!variableReplacements.containsKey(expectedVar)) {
        missingVariables.add(expectedVar);
      }
    }
    if (missingVariables.isNotEmpty) {
      print('Missing variables for $name: [${missingVariables.join(',')}]');
    }

    var translateContext = _MessageResolveTranslationContext(name: name, locale: locale, variableReplacements: variableReplacements);
    _message.accept(translateVisitor, translateContext);
    return translateContext.translationResult.toString();
  }
}

/// base class for all message resolve contexts
abstract class _MessageResolveContext {
  final String name;
  final String locale;

  _MessageResolveContext({required this.name, required this.locale});
}

/// context for an analysis run.
/// If this context is given then the visitor will only do analysis work and store the result here
class _MessageResolveAnalysisContext extends _MessageResolveContext {
  bool isSimpleText = true;
  List<String> variableNames = [];

  /// adds the given variable name if it is not yet known
  void addVariableIfNotExistent(String variableName) {
    if (!variableNames.contains(variableName)) {
      variableNames.add(variableName);
    }
  }

  /// creates a new [_MessageResolveAnalysisContext]
  _MessageResolveAnalysisContext({required String name, required String locale}) : super(name: name, locale: locale);
}

/// context for an translation run.
/// If this context is given then the visitor will only do translation work and store the result here
class _MessageResolveTranslationContext extends _MessageResolveContext {
  final translationResult = StringBuffer();
  final Map<String, String> variableReplacements;

  /// creates a new [_MessageResolveTranslationContext]
  _MessageResolveTranslationContext({required String name, required String locale, this.variableReplacements = const {}})
    : super(name: name, locale: locale);
}

/// Visitor for visiting a [Message] tree.
/// Depending on the given context this visitor will analyze the tree or execute a translation
class MessageResolveVisitor extends RecursiveMessageVisitor<_MessageResolveContext> {
  MessageResolveVisitor();

  @override
  _MessageResolveContext visitLiteralString(LiteralString message, _MessageResolveContext context) {
    if (context is _MessageResolveTranslationContext) {
      // if we are in translation mode just add this literal to the result
      context.translationResult.write(message.string);
    }
    // no effect in analysis mode
    return super.visitLiteralString(message, context);
  }

  @override
  _MessageResolveContext visitVariableSubstitution(VariableSubstitution message, _MessageResolveContext context) {
    final varName = message.variableName;
    if (context is _MessageResolveAnalysisContext) {
      // in analysis mode we
      // mark this [Message] tree as not having simple text because we know for sure that it contains variables :)
      context.isSimpleText = false;
      // add the variable to the context as analysis result
      if (varName != null) {
        context.addVariableIfNotExistent(varName.toUpperCase());
      }
    }

    if (context is _MessageResolveTranslationContext) {
      // in translation mode we check if we have a replacement for this variable
      if (varName != null && context.variableReplacements.containsKey(varName.toUpperCase())) {
        // if so then just write the variable content to the result
        context.translationResult.write(context.variableReplacements[varName.toUpperCase()]!);
      } else {
        // if not then we have a problem.
        // we log the problem and
        print('''
          'No value for variable replacement! ${context.name}, variable = $varName',
          extras: {
            'name': ${context.name},
            'variableName': ${varName ?? '<unknown>'},
          },
          ''');
        // do nothing for now (this means the variable just disappears from the translation)
      }
    }

    return super.visitVariableSubstitution(message, context);
  }

  @override
  _MessageResolveContext visitGender(Gender message, _MessageResolveContext context) {
    if (context is _MessageResolveAnalysisContext) {
      // Even if we don't support gendered translation currently we know that this is not a simple text
      context.isSimpleText = false;
    }
    print('''
      'Gender translation statements are not yet supported! ${context.name}',
      extras: {
        'name': ${context.name},
      },
      ''');
    return super.visitGender(message, context);
  }

  @override
  _MessageResolveContext visitPlural(Plural message, _MessageResolveContext context) {
    if (context is _MessageResolveAnalysisContext) {
      // No simple text, that's for sure
      context.isSimpleText = false;
      // add the plural main argument as variable
      context.addVariableIfNotExistent(message.mainArgument.toUpperCase());
      // in analysis mode we visit all potential children
      [message.zero, message.one, message.two, message.few, message.many, message.other].where((m) => m != null).forEach((m) {
        m!.accept(this, context);
      });
    } else if (context is _MessageResolveTranslationContext) {
      // in translation mode we use the value of the main argument to decide how to proceed
      final mainArgumentValue = context.variableReplacements[message.mainArgument.toUpperCase()];
      if (mainArgumentValue == null) {
        print('''
          'Missing mainArgument for plural translation ${context.name}',
          extras: {
            'name': ${context.name},
          },
          ''');
        return context;
      }

      final maybeHowMany = num.tryParse(mainArgumentValue);
      if (maybeHowMany == null) {
        print('''
          'Missing howMany parameter for plural translation ${context.name}. Expected parameter is ${message.mainArgument}',
          extras: {
            'name': ${context.name},
            'howManyArgumentName': ${message.mainArgument},
          },
          ''');
        return context;
      }

      // the actual logic for this is taken from the Intl package. Thanks to the authors for providing such a generic method ;)
      final effectiveMessage = Intl.pluralLogic<Message>(
        maybeHowMany,
        zero: message.zero,
        one: message.one,
        two: message.two,
        few: message.few,
        many: message.many,
        other: message.other!,
        locale: context.locale,
      );
      // in translation mode we only continue with the effective child
      effectiveMessage.accept(this, context);
    }
    return super.visitPlural(message, context);
  }

  @override
  _MessageResolveContext visitSelect(Select message, _MessageResolveContext context) {
    if (context is _MessageResolveAnalysisContext) {
      // Even if we don't support a select expression currently we know that this is not a simple text
      context.isSimpleText = false;
    }
    print('''
      'Select translation statements are not yet supported! ${context.name}',
      extras: {
        'name': ${context.name},
      },
      ''');
    return super.visitSelect(message, context);
  }
}

enum _LoadingState { notLoaded, loading, loaded }
