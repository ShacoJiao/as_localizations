// This file has been taken from the intl package and stuff that we don't need (like all that AST verification stuff) got ripped out

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

/// This provides classes to represent the internal structure of the
/// arguments to `Intl.message`. It is used when parsing sources to extract
/// messages or to generate code for message substitution. Normal programs
/// using Intl would not import this library.
///
/// While it's written
/// in a somewhat abstract way, it has some assumptions about ICU-style
/// message syntax for parameter substitutions, choices, selects, etc.
///
/// For example, if we have the message
///      plurals(num) => Intl.message("""${Intl.plural(num,
///          zero : 'Is zero plural?',
///          one : 'This is singular.',
///          other : 'This is plural ($num).')
///         }""",
///         name: "plurals", args: {'num': num.toString()}, desc: "Basic plurals");
/// That is represented as a MainMessage which has only one message component, a
/// Plural, but also has a name, list of arguments, and a description.
/// The Plural has three different clauses. The `zero` clause is
/// a LiteralString containing 'Is zero plural?'. The `other` clause is a
/// CompositeMessage containing three pieces, a LiteralString for
/// 'This is plural (', a VariableSubstitution for `num`. amd a LiteralString
/// for '.)'.
///
/// This representation isn't used at runtime. Rather, we read some format
/// from a translation file, parse it into these objects, and they are then
/// used to generate the code representation above.
library intl_message;

import 'intl_message_visitor.dart';

dynamic _nullTransform(msg, chunk) => chunk;

abstract class Message {
  Message? parent;

  Message(this.parent);

  List<String>? get arguments => parent == null ? const [] : parent!.arguments;

  String get name => parent == null ? '<unnamed>' : parent!.name;

  static Message from(Object value, Message? parent) {
    if (value is String) return LiteralString(value, parent);
    if (value is int) return VariableSubstitution(value, parent);
    if (value is List) {
      if (value.length == 1) return Message.from(value[0], parent);
      var result = CompositeMessage([], parent as ComplexMessage?);
      var items = value.map((x) => from(x, result)).toList();
      result.pieces.addAll(items);
      return result;
    }
    // We assume this is already a Message.
    Message mustBeAMessage = value as Message;
    mustBeAMessage.parent = parent;
    return mustBeAMessage;
  }

  R accept<R>(MessageVisitor<R> visitor, R context) {
    return visitor.visitMessage(this, context);
  }

  String expanded([Function transform]);
}

abstract class ComplexMessage extends Message {
  ComplexMessage(parent) : super(parent);

  dynamic operator [](String attributeName);

  void operator []=(String attributeName, dynamic rawValue);

  List<String> get attributeNames;

  String get icuMessageName;

  String get dartMessageName;
}

class CompositeMessage extends Message {
  List<Message> pieces = [];

  CompositeMessage.withParent(parent) : super(parent);
  CompositeMessage(this.pieces, ComplexMessage? parent) : super(parent) {
    for (var x in pieces) {
      x.parent = this;
    }
  }
  @override
  String toString() => 'CompositeMessage($pieces)';
  @override
  String expanded([Function transform = _nullTransform]) => pieces.map((chunk) => transform(this, chunk)).join('');

  @override
  R accept<R>(MessageVisitor<R> visitor, R context) {
    super.accept(visitor, context);
    return visitor.visitCompositeMessage(this, context);
  }
}

class LiteralString extends Message {
  String string;
  LiteralString(this.string, Message? parent) : super(parent);
  @override
  String toString() => 'Literal($string)';
  @override
  String expanded([Function transform = _nullTransform]) => transform(this, string);

  @override
  R accept<R>(MessageVisitor<R> visitor, R context) {
    super.accept(visitor, context);
    return visitor.visitLiteralString(this, context);
  }
}

class VariableSubstitution extends Message {
  VariableSubstitution(this._index, Message? parent) : super(parent);

  VariableSubstitution.named(String name, Message? parent) : super(parent) {
    _variableName = name;
    _variableNameUpper = name.toUpperCase();
  }

  int? _index;
  int? get index {
    if (_index != null) return _index;
    if (arguments?.isEmpty ?? true) return null;
    // We may have been given an all-uppercase version of the name, so compare
    // case-insensitive.
    _index = arguments?.map((x) => x.toUpperCase()).toList().indexOf(_variableNameUpper);
    if (_index == -1) {
      throw ArgumentError(
        "Cannot find parameter named '$_variableNameUpper' in "
        "message named '$name'. Available "
        'parameters are $arguments',
      );
    }
    return _index;
  }

  late String _variableNameUpper;

  String? get variableName => _variableName ?? (_variableName = arguments?[index!]);
  String? _variableName;

  @override
  String toString() => 'VariableSubstitution($index)';
  @override
  String expanded([Function transform = _nullTransform]) => transform(this, index);

  @override
  R accept<R>(MessageVisitor<R> visitor, R context) {
    super.accept(visitor, context);
    return visitor.visitVariableSubstitution(this, context);
  }
}

class MainMessage extends ComplexMessage {
  MainMessage() : super(null);

  List<Message> messagePieces = [];

  void addPieces(List<Object> messages) {
    for (var each in messages) {
      messagePieces.add(Message.from(each, this));
    }
  }

  String? description;

  String? meaning;

  String? _name;

  String? id;

  @override
  List<String>? arguments;

  String? locale;

  bool skip = false;

  Map<String, String> translations = {};
  Map<String, Object> jsonTranslations = {};

  @override
  String get name => _name ?? '';
  set name(String newName) {
    _name = newName;
  }

  bool get hasName => _name != null;

  @override
  String expanded([Function transform = _nullTransform]) => messagePieces.map((chunk) => transform(this, chunk)).join('');

  @override
  void operator []=(String attributeName, dynamic value) {
    switch (attributeName) {
      case 'desc':
        description = value;
        return;
      case 'name':
        name = value;
        return;
      case 'args':
        return;
      case 'meaning':
        meaning = value;
        return;
      case 'locale':
        locale = value;
        return;
      case 'skip':
        skip = value as bool;
        return;
      default:
        return;
    }
  }

  @override
  dynamic operator [](String attributeName) {
    switch (attributeName) {
      case 'desc':
        return description;
      case 'name':
        return name;
      case 'args':
        return [];
      case 'meaning':
        return meaning;
      case 'skip':
        return skip;
      default:
        return null;
    }
  }

  @override
  String get icuMessageName => '';

  @override
  String get dartMessageName => 'message';

  @override
  List<String> get attributeNames => const ['name', 'desc', 'args', 'meaning', 'skip'];

  @override
  String toString() => 'Intl.message(${expanded()}, $name, $description, $arguments)';

  @override
  R accept<R>(MessageVisitor<R> visitor, R context) {
    super.accept(visitor, context);
    return visitor.visitMainMessage(this, context);
  }
}

abstract class SubMessage extends ComplexMessage {
  SubMessage() : mainArgument = '', super(null);

  SubMessage.from(this.mainArgument, List clauses, parent) : super(parent) {
    for (var clause in clauses) {
      this[clause.first] = (clause.last is List) ? clause.last : [clause.last];
    }
  }

  @override
  String toString() => expanded();

  String mainArgument;

  List<String> get codeAttributeNames;

  @override
  String expanded([Function transform = _nullTransform]) {
    String fullMessageForClause(String key) => '$key{${transform(parent, this[key])}}';
    var clauses = attributeNames.where((key) => this[key] != null).map(fullMessageForClause).toList();
    return "{$mainArgument,$icuMessageName, ${clauses.join("")}}";
  }

  @override
  R accept<R>(MessageVisitor<R> visitor, R context) {
    super.accept(visitor, context);
    return visitor.visitSubMessage(this, context);
  }
}

class Gender extends SubMessage {
  Gender();

  Gender.from(String mainArgument, List clauses, Message? parent) : super.from(mainArgument, clauses, parent);

  Message? female;
  Message? male;
  Message? other;

  @override
  String get icuMessageName => 'select';
  @override
  String get dartMessageName => 'Intl.gender';

  @override
  List<String> get attributeNames => ['female', 'male', 'other'];
  @override
  List<String> get codeAttributeNames => attributeNames;

  @override
  void operator []=(String attributeName, dynamic rawValue) {
    var value = Message.from(rawValue, this);
    switch (attributeName) {
      case 'female':
        female = value;
        return;
      case 'male':
        male = value;
        return;
      case 'other':
        other = value;
        return;
      default:
        return;
    }
  }

  @override
  Message? operator [](String attributeName) {
    switch (attributeName) {
      case 'female':
        return female;
      case 'male':
        return male;
      case 'other':
        return other;
      default:
        return other;
    }
  }

  @override
  R accept<R>(MessageVisitor<R> visitor, R context) {
    super.accept(visitor, context);
    return visitor.visitGender(this, context);
  }
}

class Plural extends SubMessage {
  Plural();
  Plural.from(String mainArgument, List clauses, Message? parent) : super.from(mainArgument, clauses, parent);

  Message? zero;
  Message? one;
  Message? two;
  Message? few;
  Message? many;
  Message? other;

  @override
  String get icuMessageName => 'plural';
  @override
  String get dartMessageName => 'Intl.plural';

  @override
  List<String> get attributeNames => ['=0', '=1', '=2', 'few', 'many', 'other'];
  @override
  List<String> get codeAttributeNames => ['zero', 'one', 'two', 'few', 'many', 'other'];

  @override
  void operator []=(String attributeName, dynamic rawValue) {
    var value = Message.from(rawValue, this);
    switch (attributeName) {
      case 'zero':
        // We prefer an explicit "=0" clause to a "ZERO"
        // if both are present.
        zero ??= value;
        return;
      case '=0':
        zero = value;
        return;
      case 'one':
        // We prefer an explicit "=1" clause to a "ONE"
        // if both are present.
        one ??= value;
        return;
      case '=1':
        one = value;
        return;
      case 'two':
        // We prefer an explicit "=2" clause to a "TWO"
        // if both are present.
        two ??= value;
        return;
      case '=2':
        two = value;
        return;
      case 'few':
        few = value;
        return;
      case 'many':
        many = value;
        return;
      case 'other':
        other = value;
        return;
      default:
        return;
    }
  }

  @override
  Message? operator [](String attributeName) {
    switch (attributeName) {
      case 'zero':
        return zero;
      case '=0':
        return zero;
      case 'one':
        return one;
      case '=1':
        return one;
      case 'two':
        return two;
      case '=2':
        return two;
      case 'few':
        return few;
      case 'many':
        return many;
      case 'other':
        return other;
      default:
        return other;
    }
  }

  @override
  R accept<R>(MessageVisitor<R> visitor, R context) {
    super.accept(visitor, context);
    return visitor.visitPlural(this, context);
  }
}

class Select extends SubMessage {
  Select();

  Select.from(String mainArgument, List clauses, Message? parent) : super.from(mainArgument, clauses, parent);

  Map<String, Message> cases = <String, Message>{};

  @override
  String get icuMessageName => 'select';
  @override
  String get dartMessageName => 'Intl.select';

  @override
  List<String> get attributeNames => cases.keys.toList();
  @override
  List<String> get codeAttributeNames => attributeNames;

  // Check for valid select keys.
  // See http://site.icu-project.org/design/formatting/select
  static const selectPattern = '[a-zA-Z][a-zA-Z0-9_-]*';
  static final validSelectKey = RegExp(selectPattern);

  @override
  void operator []=(String attributeName, dynamic rawValue) {
    var value = Message.from(rawValue, this);
    if (validSelectKey.stringMatch(attributeName) == attributeName) {
      cases[attributeName] = value;
    } else {
      throw IntlMessageExtractionException(
        "Invalid select keyword: '$attributeName', must "
        "match '$selectPattern'",
      );
    }
  }

  @override
  Message operator [](String attributeName) {
    var exact = cases[attributeName];
    return exact ?? cases['other']!;
  }

  @override
  R accept<R>(MessageVisitor<R> visitor, R context) {
    super.accept(visitor, context);
    return visitor.visitSelect(this, context);
  }
}

class IntlMessageExtractionException implements Exception {
  final String message;

  const IntlMessageExtractionException([this.message = '']);

  @override
  String toString() => 'IntlMessageExtractionException: $message';
}
