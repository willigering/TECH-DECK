import 'dart:math';

/// Zufällige Reihenfolge innerhalb eines Decks.
List<T> shuffledCopy<T>(List<T> items, [Random? random]) {
  final copy = List<T>.from(items);
  if (copy.length > 1) {
    copy.shuffle(random ?? Random());
  }
  return copy;
}
