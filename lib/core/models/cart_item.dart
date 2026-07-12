import '../models/product.dart';

// ─── Cart Item ────────────────────────────────────────────────────────────────
class CartItem {
  final int productId;        // product.product ID
  final int templateId;       // product.template ID
  final String name;
  final double price;
  int quantity;
  final String? imageUrl;
  final String? variantName;  // e.g. "Blue, 3-6m"

  CartItem({
    required this.productId,
    required this.templateId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.variantName,
  });

  factory CartItem.fromProduct(Product product, {int qty = 1, int? variantId, String? variantName}) {
    return CartItem(
      productId: variantId ?? (product.variantIds.isNotEmpty ? product.variantIds.first : product.id),
      templateId: product.id,
      name: product.name,
      price: product.price,
      quantity: qty,
      imageUrl: product.imageUrl,
      variantName: variantName,
    );
  }

  factory CartItem.fromVariant(ProductVariant variant, Product template, {int qty = 1}) {
    return CartItem(
      productId: variant.id,
      templateId: template.id,
      name: template.name,
      price: variant.price,
      quantity: qty,
      imageUrl: variant.imageUrl ?? template.imageUrl,
      variantName: _extractVariantName(variant.name, template.name),
    );
  }

  static String? _extractVariantName(String variantFullName, String templateName) {
    if (variantFullName == templateName) return null;
    final suffix = variantFullName.replaceFirst(templateName, '').trim();
    if (suffix.startsWith('(') && suffix.endsWith(')')) {
      return suffix.substring(1, suffix.length - 1);
    }
    return suffix.isEmpty ? null : suffix;
  }

  double get subtotal => price * quantity;
  String get formattedPrice => '${price.toStringAsFixed(0)} LE';
  String get formattedSubtotal => '${subtotal.toStringAsFixed(0)} LE';

  // For creating Odoo sale.order line
  Map<String, dynamic> toOrderLine() => {
    'product_id': productId,
    'product_uom_qty': quantity.toDouble(),
    'price_unit': price,
    'name': variantName != null ? '$name ($variantName)' : name,
  };

  CartItem copyWith({int? quantity}) => CartItem(
    productId: productId,
    templateId: templateId,
    name: name,
    price: price,
    quantity: quantity ?? this.quantity,
    imageUrl: imageUrl,
    variantName: variantName,
  );
}
