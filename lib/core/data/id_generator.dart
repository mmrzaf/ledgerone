import 'package:uuid/uuid.dart';

/// Simple ID generator interface
abstract class IdGenerator {
  String generate();
}

/// UUID-based ID generator
class UuidIdGenerator implements IdGenerator {
  static const _uuid = Uuid();

  @override
  String generate() => _uuid.v4();
}

/// Singleton instance for convenience
final idGenerator = UuidIdGenerator();
