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
    // Defensive parsing: the in-memory backend may return wrong types
    // (e.g. image_url = true due to swapped params). Never hard-cast.
    final rawImageUrl = json['image_url'];
    final rawCategoryId = json['category_id'];
    final rawInStock = json['in_stock'];

    return Product(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      // category_id can legitimately be null; guard against non-String
      categoryId: rawCategoryId is String ? rawCategoryId : null,
      name: json['name'] as String,
      price: double.parse(json['price'].toString()),
      unit: json['unit'] as String,
      // in_stock may arrive as bool or int (0/1) from different DB drivers
      inStock: rawInStock is bool
          ? rawInStock
          : (rawInStock is int ? rawInStock != 0 : true),
      // image_url may be null, a String URL, or accidentally a bool/int — only keep Strings
      imageUrl: rawImageUrl is String ? rawImageUrl : null,
    );
  }
}
