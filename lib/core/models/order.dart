// ─── Sale Order ───────────────────────────────────────────────────────────────
class SaleOrder {
  final int id;
  final String name;
  final DateTime dateOrder;
  final double amountTotal;
  final String state;
  final String currency;
  final List<int> orderLineIds;

  const SaleOrder({
    required this.id,
    required this.name,
    required this.dateOrder,
    required this.amountTotal,
    required this.state,
    required this.currency,
    required this.orderLineIds,
  });

  factory SaleOrder.fromJson(Map<String, dynamic> json) {
    return SaleOrder(
      id: json['id'] as int,
      name: json['name'] as String,
      dateOrder: DateTime.tryParse(json['date_order'] as String? ?? '') ??
          DateTime.now(),
      amountTotal: (json['amount_total'] as num).toDouble(),
      state: json['state'] as String? ?? 'draft',
      currency: json['currency_id'] is List
          ? (json['currency_id'] as List)[1] as String
          : 'EGP',
      orderLineIds: json['order_line'] is List
          ? List<int>.from(json['order_line'])
          : [],
    );
  }

  String get formattedTotal => '${amountTotal.toStringAsFixed(0)} LE';

  String get stateLabel {
    switch (state) {
      case 'draft':
        return 'مسودة';
      case 'sent':
        return 'تم الإرسال';
      case 'sale':
        return 'قيد التنفيذ';
      case 'done':
        return 'مكتمل';
      case 'cancel':
        return 'ملغي';
      default:
        return state;
    }
  }

  String get stateEmoji {
    switch (state) {
      case 'draft':
        return '📝';
      case 'sent':
        return '📨';
      case 'sale':
        return '🚀';
      case 'done':
        return '✅';
      case 'cancel':
        return '❌';
      default:
        return '📋';
    }
  }
}

// ─── Order Line ───────────────────────────────────────────────────────────────
class OrderLine {
  final int id;
  final String productName;
  final double qty;
  final double priceUnit;
  final double priceSubtotal;

  const OrderLine({
    required this.id,
    required this.productName,
    required this.qty,
    required this.priceUnit,
    required this.priceSubtotal,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      id: json['id'] as int,
      productName: json['name'] as String? ?? 'Product',
      qty: (json['product_uom_qty'] as num).toDouble(),
      priceUnit: (json['price_unit'] as num).toDouble(),
      priceSubtotal: (json['price_subtotal'] as num).toDouble(),
    );
  }

  String get formattedSubtotal => '${priceSubtotal.toStringAsFixed(0)} LE';
}
