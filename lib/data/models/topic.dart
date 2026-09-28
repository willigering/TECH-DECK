class Topic {
  const Topic({
    required this.id,
    required this.name,
    required this.sourceFilename,
    required this.sortOrder,
    required this.importedAt,
    this.cardCount = 0,
    this.colorKey,
    this.isImportant = false,
  });

  final String id;
  final String name;
  final String sourceFilename;
  final int sortOrder;
  final DateTime importedAt;
  final int cardCount;
  final String? colorKey;
  final bool isImportant;

  Topic copyWith({
    String? id,
    String? name,
    String? sourceFilename,
    int? sortOrder,
    DateTime? importedAt,
    int? cardCount,
    String? colorKey,
    bool clearColor = false,
    bool? isImportant,
  }) {
    return Topic(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceFilename: sourceFilename ?? this.sourceFilename,
      sortOrder: sortOrder ?? this.sortOrder,
      importedAt: importedAt ?? this.importedAt,
      cardCount: cardCount ?? this.cardCount,
      colorKey: clearColor ? null : (colorKey ?? this.colorKey),
      isImportant: isImportant ?? this.isImportant,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'source_filename': sourceFilename,
    'sort_order': sortOrder,
    'imported_at': importedAt.millisecondsSinceEpoch,
    'accent_color': colorKey,
    'is_important': isImportant ? 1 : 0,
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
      colorKey: _colorKey(map['accent_color']),
      isImportant: _asBool(map['is_important']),
    );
  }

  static String? _colorKey(Object? value) {
    if (value is! String) return null;
    final key = value.trim();
    return key.isEmpty ? null : key;
  }

  static bool _asBool(Object? value) {
    if (value == true || value == 1) return true;
    if (value is num) return value != 0;
    return false;
  }
}
