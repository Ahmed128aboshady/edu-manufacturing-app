import 'package:flutter/foundation.dart';
import '../services/odoo_service.dart';
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  final OdooService _odoo = OdooService();

  List<SaleOrder> _orders = [];
  bool _isLoading = false;
  bool _isCreating = false;
  String? _errorMessage;
  int? _lastCreatedOrderId;

  List<SaleOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get errorMessage => _errorMessage;
  int? get lastCreatedOrderId => _lastCreatedOrderId;

  Future<void> loadOrders(int partnerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _odoo.getMyOrders(partnerId);
      _orders = data.map((json) => SaleOrder.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load orders.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<int?> createOrder({
    required int partnerId,
    required List<Map<String, dynamic>> orderLines,
    String? deliveryAddress,
    String? phone,
    String? note,
  }) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orderNote = [
        'Order placed via Mobile App',
        'Payment: Cash on Delivery (COD)',
        if (deliveryAddress != null) 'Address: $deliveryAddress',
        if (phone != null) 'Phone: $phone',
        if (note != null) 'Note: $note',
      ].join('\n');

      final orderId = await _odoo.createSaleOrder(
        partnerId: partnerId,
        orderLines: orderLines,
        note: orderNote,
      );

      _lastCreatedOrderId = orderId;

      // Reload orders
      await loadOrders(partnerId);

      _isCreating = false;
      notifyListeners();
      return orderId;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isCreating = false;
      notifyListeners();
      return null;
    }
  }

  Future<List<OrderLine>> getOrderLines(int orderId) async {
    try {
      final data = await _odoo.getOrderLines(orderId);
      return data.map((json) => OrderLine.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
