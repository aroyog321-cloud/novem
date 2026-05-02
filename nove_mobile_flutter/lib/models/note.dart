/// Note model representing a note in the database
class Note {
  final String id;
  final String title;
  final String content;
  final String? category;
  final String colorLabel;
  final bool isPinned;
  final bool isFavorite;
  final int createdAt;
  final int updatedAt;
  final int wordCount;
  final int charCount;
  final double readTimeMinutes;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.category,
    required this.colorLabel,
    required this.isPinned,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    required this.wordCount,
    required this.charCount,
    required this.readTimeMinutes,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      category: map['category']?.toString(),
      colorLabel: map['color_label']?.toString() ?? '#FFFFFF',
      isPinned: map['is_pinned'] == 1 || map['is_pinned'] == true || map['is_pinned'] == '1',
      isFavorite: map['is_favorite'] == 1 || map['is_favorite'] == true || map['is_favorite'] == '1',
      createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
      updatedAt: (map['updated_at'] as num?)?.toInt() ?? 0,
      wordCount: (map['word_count'] as num?)?.toInt() ?? 0,
      charCount: (map['char_count'] as num?)?.toInt() ?? 0,
      readTimeMinutes: (map['read_time_minutes'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory Note.fromJson(Map<String, dynamic> json) => Note.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'color_label': colorLabel,
      'is_pinned': isPinned ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'word_count': wordCount,
      'char_count': charCount,
      'read_time_minutes': readTimeMinutes,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    String? colorLabel,
    bool? isPinned,
    bool? isFavorite,
    int? createdAt,
    int? updatedAt,
    int? wordCount,
    int? charCount,
    double? readTimeMinutes,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      colorLabel: colorLabel ?? this.colorLabel,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      wordCount: wordCount ?? this.wordCount,
      charCount: charCount ?? this.charCount,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
    );
  }
}
