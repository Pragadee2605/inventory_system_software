class Category {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });
}
