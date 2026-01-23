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
      id: json['_id'],
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
      id: json['_id'],
      text: json['text'],
      answer: json['answer'],
      level: json['level'],
      categoryId: json['categoryId']['_id'] ?? json['categoryId'],
    );
  }
}
