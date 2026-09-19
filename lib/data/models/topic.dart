class Topic {
  const Topic({
    required this.id,
    required this.name,
    required this.sourceFilename,
    required this.sortOrder,
    required this.importedAt,
    this.cardCount = 0,
  });

  final String id;
  final String name;
  final String sourceFilename;
  final int sortOrder;
  final DateTime importedAt;
  final int cardCount;

  Topic copyWith({
    String? id,
    String? name,
    String? sourceFilename,
    int? sortOrder,
    DateTime? importedAt,
    int? cardCount,
  }) {
    return Topic(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceFilename: sourceFilename ?? this.sourceFilename,
      sortOrder: sortOrder ?? this.sortOrder,
      importedAt: importedAt ?? this.importedAt,
      cardCount: cardCount ?? this.cardCount,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'source_filename': sourceFilename,
    'sort_order': sortOrder,
    'imported_at': importedAt.millisecondsSinceEpoch,
  };

  factory Topic.fromMap(Map<String, Object?> map, {int cardCount = 0}) {
    return Topic(
      id: map['id'] as String,
      name: map['name'] as String,
      sourceFilename: map['source_filename'] as String,
      sortOrder: map['sort_order'] as int,
      importedAt: DateTime.fromMillisecondsSinceEpoch(
        map['imported_at'] as int,
      ),
      cardCount: cardCount,
    );
  }
}
