class Supplier {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    required this.createdAt,
  });
}
