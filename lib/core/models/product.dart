// ─── Product Model ────────────────────────────────────────────────────────────
class Product {
  final int id;
  final String name;
  final double price;
  final String? description;
  final String? imageUrl;
  final List<int> variantIds;
  final int variantCount;
  final String? websiteUrl;
  final List<AttributeLine> attributeLines;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    required this.variantIds,
    required this.variantCount,
    this.websiteUrl,
    required this.attributeLines,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['list_price'] as num).toDouble(),
      description: json['description_sale'] is String
          ? json['description_sale'] as String
          : null,
      imageUrl: _buildImageUrl(json['id'] as int),
      variantIds: _parseIntList(json['product_variant_ids']),
      variantCount: json['product_variant_count'] as int? ?? 1,
      websiteUrl: json['website_url'] as String?,
      attributeLines: _parseIntList(json['attribute_line_ids'])
          .map((id) => AttributeLine(id: id))
          .toList(),
    );
  }

  static String _buildImageUrl(int id) =>
      'https://edu-manufacturing-general.odoo.com/web/image/product.template/$id/image_512';

  static List<int> _parseIntList(dynamic val) {
    if (val is List) return val.map((e) => e as int).toList();
    return [];
  }

  String get formattedPrice => '${price.toStringAsFixed(0)} LE';
}

// ─── Attribute Line ───────────────────────────────────────────────────────────
class AttributeLine {
  final int id;
  AttributeLine({required this.id});
}

// ─── Product Variant ──────────────────────────────────────────────────────────
class ProductVariant {
  final int id;
  final String name;
  final double price;
  final String? imageUrl;
  final double stockQty;

  const ProductVariant({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.stockQty,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['list_price'] as num).toDouble(),
      imageUrl: json['id'] != null
          ? 'https://edu-manufacturing-general.odoo.com/web/image/product.product/${json['id']}/image_512'
          : null,
      stockQty: (json['qty_available'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get formattedPrice => '${price.toStringAsFixed(0)} LE';
  bool get isInStock => stockQty > 0;
}

// ─── Product Category ────────────────────────────────────────────────────────
class ProductCategory {
  final int id;
  final String name;
  final String? imageUrl;
  final int? parentId;

  const ProductCategory({
    required this.id,
    required this.name,
    this.imageUrl,
    this.parentId,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: json['id'] != null
          ? 'https://edu-manufacturing-general.odoo.com/web/image/product.public.category/${json['id']}/image_1024'
          : null,
      parentId: json['parent_id'] is List
          ? (json['parent_id'] as List)[0] as int?
          : null,
    );
  }
}
