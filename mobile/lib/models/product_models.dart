/// A product category, scoped to one shop (e.g. "Grains", "Dairy").
class Category {
  final String id;
  final String shopId;
  final String name;

  Category({required this.id, required this.shopId, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      name: json['name'] as String,
    );
  }
}

/// A product in a shop's catalog.
class Product {
  final String id;
  final String shopId;
  final String? categoryId;
  final String name;
  final double price;
  final String unit;
  final bool inStock;
  final String? imageUrl;

  Product({
    required this.id,
    required this.shopId,
    this.categoryId,
    required this.name,
    required this.price,
    required this.unit,
    required this.inStock,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      categoryId: json['category_id'] as String?,
      name: json['name'] as String,
      price: double.parse(json['price'].toString()),
      unit: json['unit'] as String,
      inStock: json['in_stock'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
    );
  }
}
