import 'package:equatable/equatable.dart';

abstract class Translator {
  String translate({required String defaultEn, required String sid, Map<String, Object>? args});

  String plural(int howMany, {required PluralStrings enStrings, required String sid, Map<String, Object>? args});
}

/// represents a set of plural strings for one language
class PluralStrings extends Equatable {
  /// 0-case
  final String? zero;

  /// 1-case
  final String? one;

  /// 2-case
  final String? two;

  /// few-case
  final String? few;

  /// many-case
  final String? many;

  /// default string used if no other category matches or has a value
  final String other;

  const PluralStrings({this.zero, this.one, this.two, this.few, this.many, required this.other});

  @override
  List<Object?> get props => [zero, one, two, few, many, other];
}
