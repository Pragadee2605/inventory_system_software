class Product {
  final int id;
  final String sku;
  final String? barcode;
  final String name;
  final int categoryId;
  final String categoryName;
  final int? brandId;
  final String? brandName;
  final double purchasePrice;
  final double sellingPrice;
  final int currentStock;
  final int minStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.sku,
    this.barcode,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    this.brandId,
    this.brandName,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.currentStock,
    required this.minStock,
    required this.createdAt,
    required this.updatedAt,
  });
}
