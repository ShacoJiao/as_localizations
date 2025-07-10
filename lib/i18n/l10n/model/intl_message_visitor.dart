import 'intl_message.dart';

abstract class MessageVisitor<T> {
  T visitMessage(Message message, T context);

  T visitLeafMessage(Message message, T context);

  T visitCompositeMessage(CompositeMessage message, T context);

  T visitLiteralString(LiteralString message, T context);

  T visitVariableSubstitution(VariableSubstitution message, T context);

  T visitMainMessage(MainMessage message, T context);

  T visitSubMessage(SubMessage message, T context);

  T visitGender(Gender message, T context);

  T visitPlural(Plural message, T context);

  T visitSelect(Select message, T context);
}

abstract class RecursiveMessageVisitor<T> implements MessageVisitor<T> {
  @override
  T visitMessage(Message message, T context) {
    return context;
  }

  @override
  T visitLeafMessage(Message message, T context) {
    return context;
  }

  @override
  T visitCompositeMessage(CompositeMessage message, T context) {
    message.pieces.forEach((m) {
      context = m.accept(this, context);
    });
    return context;
  }

  @override
  T visitLiteralString(LiteralString message, T context) {
    return context;
  }

  @override
  T visitVariableSubstitution(VariableSubstitution message, T context) {
    return context;
  }

  @override
  T visitMainMessage(MainMessage message, T context) {
    message.messagePieces.forEach((m) {
      context = m.accept(this, context);
    });
    return context;
  }

  @override
  T visitSubMessage(SubMessage message, T context) {
    return context;
  }

  @override
  T visitGender(Gender message, T context) {
    return context;
  }

  @override
  T visitPlural(Plural message, T context) {
    return context;
  }

  @override
  T visitSelect(Select message, T context) {
    return context;
  }
}
