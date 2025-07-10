enum IsoCountry {
  China,
  UnitedStates,
  SouthKorea,
  Spain,
  Philippines,
  France,
  Japan,
  Portugal,
  Thailand,
  Turkey,
  VietNam,
  Iran,
  Germany,
  SaudiArabia,
  Israel,
  Italy,
  RussianFederation,
  Malaysia,
  HongKong,
  Taiwan,
}

String IsoCountryToString(IsoCountry isoCountry) {
  switch (isoCountry) {
    case IsoCountry.China:
      return 'CN';
    case IsoCountry.France:
      return 'FR';
    case IsoCountry.Germany:
      return 'DE';
    case IsoCountry.HongKong:
      return 'HK';
    case IsoCountry.Israel:
      return 'IL';
    case IsoCountry.Italy:
      return 'IT';
    case IsoCountry.Japan:
      return 'JP';
    case IsoCountry.SouthKorea:
      return 'KR';
    case IsoCountry.Malaysia:
      return 'MY';
    case IsoCountry.Philippines:
      return 'PH';
    case IsoCountry.Portugal:
      return 'PT';
    case IsoCountry.RussianFederation:
      return 'RU';
    case IsoCountry.SaudiArabia:
      return 'SA';
    case IsoCountry.Spain:
      return 'ES';
    case IsoCountry.Thailand:
      return 'TH';
    case IsoCountry.Turkey:
      return 'TR';
    case IsoCountry.UnitedStates:
      return 'US';
    case IsoCountry.VietNam:
      return 'VN';
    case IsoCountry.Iran:
      return 'IR';
    case IsoCountry.Taiwan:
      return 'TW';
  }
}

IsoCountry? StringToIsoCountry(String country) {
  return _CountryStringToIsoEnumMap[country];
}

const _CountryStringToIsoEnumMap = <String, IsoCountry>{
  'CN': IsoCountry.China,
  'FR': IsoCountry.France,
  'DE': IsoCountry.Germany,
  'HK': IsoCountry.HongKong,
  'IL': IsoCountry.Israel,
  'IT': IsoCountry.Italy,
  'IR': IsoCountry.Iran,
  'JP': IsoCountry.Japan,
  'KR': IsoCountry.SouthKorea,
  'MY': IsoCountry.Malaysia,
  'PH': IsoCountry.Philippines,
  'PT': IsoCountry.Portugal,
  'RU': IsoCountry.RussianFederation,
  'SA': IsoCountry.SaudiArabia,
  'ES': IsoCountry.Spain,
  'TH': IsoCountry.Thailand,
  'TR': IsoCountry.Turkey,
  'US': IsoCountry.UnitedStates,
  'VN': IsoCountry.VietNam,
  'TW': IsoCountry.Taiwan,
};
