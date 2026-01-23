class Category {
  final String id;
  final String name;
  final String? description;
  final String hexColor;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.hexColor = '#FF0000',
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: _parseId(json['_id']),
      name: json['name'],
      description: json['description'],
      hexColor: json['hexColor'] ?? '#FF0000',
      isActive: json['isActive'] ?? true,
    );
  }
}

class Question {
  final String id;
  final String text;
  final String answer;
  final int level;
  final String categoryId;

  Question({
    required this.id,
    required this.text,
    required this.answer,
    required this.level,
    required this.categoryId,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: _parseId(json['_id']),
      text: json['text'],
      answer: json['answer'],
      level: json['level'],
      categoryId: _parseId(json['categoryId']),
    );
  }
}

String _parseId(dynamic id) {
  if (id == null) return '';
  if (id is String) {
    // Handle literal "ObjectId('...')" if it somehow ends up in the string
    if (id.startsWith("ObjectId('") && id.endsWith("')")) {
      return id.substring(10, id.length - 2);
    }
    return id;
  }
  if (id is Map) {
    if (id.containsKey('\$oid')) {
      return id['\$oid'] as String;
    }
    if (id.containsKey('_id')) {
      return _parseId(id['_id']);
    }
  }
  return id.toString();
}
