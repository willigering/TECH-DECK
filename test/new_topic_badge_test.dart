import 'package:flutter_test/flutter_test.dart';
import 'package:tech_deck/data/models/topic.dart';

void main() {
  final start = DateTime(2026, 10, 1, 12);
  final topic = Topic(
    id: 'new', name: 'New', sourceFilename: 'new.csv', sortOrder: 0,
    importedAt: start, newUntil: start.add(const Duration(days: 7)),
  );
  test('New badge expires exactly seven days after the first launch', () {
    expect(topic.isNewAt(start), isTrue);
    expect(topic.isNewAt(start.add(const Duration(days: 7)) - const Duration(microseconds: 1)), isTrue);
    expect(topic.isNewAt(start.add(const Duration(days: 7))), isFalse);
  });
  test('Existing topics have no new badge and copying preserves expiry', () {
    expect(Topic(id: 'old', name: 'Old', sourceFilename: 'old.csv', sortOrder: 1, importedAt: start).isNewAt(start), isFalse);
    expect(topic.copyWith(cardCount: 50).newUntil, topic.newUntil);
  });
}
