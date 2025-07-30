enum IsoLanguage {
  English,
  Chinese,
  Korean,
  Spanish,
  French,
  Filipino,
  Japanese,
  Portuguese,
  Thai,
  Turkish,
  Vietnam,
  Persian,
  German,
  Arabic,
  Hebrew,
  Italian,
  Russian,
  Malay,
  Indonesian,
}

String IsoLanguageToString(IsoLanguage isoLanguage) {
  switch (isoLanguage) {
    case IsoLanguage.Arabic:
      return 'ar';
    case IsoLanguage.German:
      return 'de';
    case IsoLanguage.English:
      return 'en';
    case IsoLanguage.Spanish:
      return 'es';
    case IsoLanguage.Persian:
      return 'fa';
    case IsoLanguage.French:
      return 'fr';
    case IsoLanguage.Hebrew:
      return 'he';
    case IsoLanguage.Italian:
      return 'it';
    case IsoLanguage.Japanese:
      return 'ja';
    case IsoLanguage.Korean:
      return 'ko';
    case IsoLanguage.Malay:
      return 'ms';
    case IsoLanguage.Portuguese:
      return 'pt';
    case IsoLanguage.Russian:
      return 'ru';
    case IsoLanguage.Thai:
      return 'th';
    case IsoLanguage.Turkish:
      return 'tr';
    case IsoLanguage.Chinese:
      return 'zh';
    case IsoLanguage.Filipino:
      return 'fil';
    case IsoLanguage.Vietnam:
      return 'vi';
    case IsoLanguage.Indonesian:
      return 'id';
  }
}

IsoLanguage? LanguageStringToIsoLanguage(String language) {
  return _LanguageStringToIsoEnumMap[language];
}

const _LanguageStringToIsoEnumMap = <String, IsoLanguage>{
  'ar': IsoLanguage.Arabic,
  'de': IsoLanguage.German,
  'en': IsoLanguage.English,
  'es': IsoLanguage.Spanish,
  'fa': IsoLanguage.Persian,
  'fr': IsoLanguage.French,
  'he': IsoLanguage.Hebrew,
  'it': IsoLanguage.Italian,
  'ja': IsoLanguage.Japanese,
  'ko': IsoLanguage.Korean,
  'ms': IsoLanguage.Malay,
  'pt': IsoLanguage.Portuguese,
  'ru': IsoLanguage.Russian,
  'th': IsoLanguage.Thai,
  'tr': IsoLanguage.Turkish,
  'zh': IsoLanguage.Chinese,
  'fil': IsoLanguage.Filipino,
  'vi': IsoLanguage.Vietnam,
  'id': IsoLanguage.Indonesian,
};
