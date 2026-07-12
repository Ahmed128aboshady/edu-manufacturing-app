import 'package:flutter/foundation.dart';
import '../services/odoo_service.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final OdooService _odoo = OdooService();

  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _currentPage = 0;
  static const int _pageSize = 21;

  // Filters
  String _searchQuery = '';
  int? _selectedCategoryId;
  String? _selectedColor;
  String? _selectedSize;
  double _minPrice = 0;
  double _maxPrice = 600;

  List<Product> get products => _products;
  List<ProductCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get selectedColor => _selectedColor;
  String? get selectedSize => _selectedSize;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;

  Future<void> loadCategories() async {
    try {
      final data = await _odoo.getCategories();
      _categories = data.map((json) => ProductCategory.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      // Fallback static categories from website scan
      _categories = [
        ProductCategory(id: 1, name: 'Men'),
        ProductCategory(id: 2, name: 'Women'),
        ProductCategory(id: 3, name: 'Kids'),
      ];
      notifyListeners();
    }
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _products = [];
      _currentPage = 0;
      _hasMore = true;
    }
    if (!_hasMore) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final domain = _buildDomain();
      final data = await _odoo.getProducts(
        domain: domain,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      final newProducts = data.map((json) => Product.fromJson(json)).toList();

      if (refresh) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      _hasMore = newProducts.length == _pageSize;
      _currentPage++;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception:', '').trim();
      if (msg == 'SESSION_EXPIRED') {
        _errorMessage = 'Session expired';
      } else {
        _errorMessage = msg;
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Product?> getProductById(int id) async {
    // Check cache first
    final cached = _products.where((p) => p.id == id).toList();
    if (cached.isNotEmpty) return cached.first;

    try {
      final json = await _odoo.getProductDetail(id);
      return json.isNotEmpty ? Product.fromJson(json) : null;
    } catch (_) {
      return null;
    }
  }

  List<dynamic> _buildDomain() {
    final domain = <dynamic>[];
    // Only filter by name search if user typed something
    if (_searchQuery.isNotEmpty) {
      domain.add(['name', 'ilike', _searchQuery]);
    }
    // Only filter by category if one is selected
    if (_selectedCategoryId != null && _selectedCategoryId != 0) {
      domain.add(['public_categ_ids', 'in', [_selectedCategoryId]]);
    }
    return domain;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadProducts(refresh: true);
  }

  void setCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    loadProducts(refresh: true);
  }

  void setFilters({String? color, String? size, double? minPrice, double? maxPrice}) {
    _selectedColor = color;
    _selectedSize = size;
    if (minPrice != null) _minPrice = minPrice;
    if (maxPrice != null) _maxPrice = maxPrice;
    loadProducts(refresh: true);
  }

  void clearFilters() {
    _selectedColor = null;
    _selectedSize = null;
    _selectedCategoryId = null;
    _searchQuery = '';
    _minPrice = 0;
    _maxPrice = 600;
    loadProducts(refresh: true);
  }
}
