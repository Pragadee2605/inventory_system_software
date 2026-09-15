class Customer {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.createdAt,
  });
}
