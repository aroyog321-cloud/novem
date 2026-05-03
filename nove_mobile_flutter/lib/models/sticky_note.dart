enum StickyColor { yellow, pink, green, blue }

class LinkedApp {
  final String packageName;
  final String name;

  const LinkedApp({required this.packageName, required this.name});

  Map<String, dynamic> toMap() => {'packageName': packageName, 'name': name};
  factory LinkedApp.fromMap(Map<String, dynamic> map) => LinkedApp(
    packageName: map['packageName'] as String,
    name: map['name'] as String,
  );
}

class StickyNote {
  final String id;
  final String title;
  final String content;
  final StickyColor color;
  final int createdAt;
  final LinkedApp? linkedApp;

  const StickyNote({
    required this.id,
    required this.title,
    required this.content,
    required this.color,
    required this.createdAt,
    this.linkedApp,
  });

  StickyNote copyWith({
    String? id,
    String? title,
    String? content,
    StickyColor? color,
    int? createdAt,
    LinkedApp? linkedApp,
    bool clearLink = false,
  }) {
    return StickyNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      linkedApp: clearLink ? null : (linkedApp ?? this.linkedApp),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'color': color.name,
      'created_at': createdAt,
      'linked_app': linkedApp?.toMap(),
    };
  }

  factory StickyNote.fromMap(Map<String, dynamic> map) {
    return StickyNote(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      color: StickyColor.values.firstWhere(
        (c) => c.name == map['color'],
        orElse: () => StickyColor.yellow,
      ),
      createdAt: map['created_at'] as int,
      linkedApp: map['linked_app'] != null 
          ? LinkedApp.fromMap(Map<String, dynamic>.from(map['linked_app'])) 
          : null,
    );
  }
}