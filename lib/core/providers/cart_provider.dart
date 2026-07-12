import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  String get formattedTotal => '${totalAmount.toStringAsFixed(0)} LE';
  bool get isEmpty => _items.isEmpty;

  void addItem(Product product, {int qty = 1, int? variantId, String? variantName, double? variantPrice}) {
    final targetProductId = variantId ?? (product.variantIds.isNotEmpty ? product.variantIds.first : product.id);
    final existingIndex = _items.indexWhere(
      (item) => item.productId == targetProductId,
    );

    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + qty,
      );
    } else {
      _items.add(CartItem(
        productId: targetProductId,
        templateId: product.id,
        name: product.name,
        price: variantPrice ?? product.price,
        quantity: qty,
        imageUrl: product.imageUrl,
        variantName: variantName,
      ));
    }
    notifyListeners();
  }

  void addVariant(ProductVariant variant, Product template, {int qty = 1}) {
    final existingIndex = _items.indexWhere(
      (item) => item.productId == variant.id,
    );

    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + qty,
      );
    } else {
      _items.add(CartItem.fromVariant(variant, template, qty: qty));
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toOrderLines() {
    return _items.map((item) => item.toOrderLine()).toList();
  }

  bool hasProduct(int productId) {
    return _items.any((item) => item.productId == productId);
  }

  int getQuantity(int productId) {
    final item = _items.where((item) => item.productId == productId).toList();
    return item.isNotEmpty ? item.first.quantity : 0;
  }
}
