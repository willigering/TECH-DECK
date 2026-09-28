import 'package:flutter_test/flutter_test.dart';
import 'package:tech_deck/core/topic_marks.dart';
import 'package:tech_deck/data/models/topic.dart';

void main() {
  test('Topic liest Farbe und Wichtig aus der Datenbankzeile', () {
    final topic = Topic.fromMap({
      'id': 'a',
      'name': 'Klausurvorbereitung',
      'source_filename': '17_Klausurvorbereitung.csv',
      'sort_order': 16,
      'imported_at': 0,
      'accent_color': TopicMarks.examKey,
      'is_important': 1,
    }, cardCount: 100);

    expect(topic.colorKey, TopicMarks.examKey);
    expect(topic.isImportant, isTrue);
    expect(TopicMarks.colorOf(topic.colorKey), isNotNull);
  });

  test('Leere Farbmarkierung wird zu null', () {
    final topic = Topic.fromMap({
      'id': 'b',
      'name': 'IT Grundlagen',
      'source_filename': '01_IT_Grundlagen.csv',
      'sort_order': 0,
      'imported_at': 0,
      'accent_color': '',
      'is_important': 0,
    });
    expect(topic.colorKey, isNull);
    expect(topic.isImportant, isFalse);
  });
}
