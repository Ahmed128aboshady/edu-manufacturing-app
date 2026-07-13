import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class OdooService {
  static final OdooService _instance = OdooService._internal();
  factory OdooService() => _instance;
  OdooService._internal();

  late final Dio _dio;
  String? _sessionId;
  int? _userId;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_sessionId != null) {
            options.headers['Cookie'] = 'session_id=$_sessionId';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Extract session cookie from response
          final cookies = response.headers.map['set-cookie'];
          if (cookies != null) {
            for (final cookie in cookies) {
              if (cookie.startsWith('session_id=')) {
                _sessionId = cookie.split(';')[0].split('=')[1];
              }
            }
          }
          handler.next(response);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> authenticate(String email, String password) async {
    final response = await _dio.post(
      ApiConstants.authenticate,
      data: {
        'jsonrpc': '2.0',
        'method': 'call',
        'id': 1,
        'params': {
          'db': ApiConstants.db,
          'login': email,
          'password': password,
        },
      },
    );
    final result = response.data['result'];
    if (result != null && result['uid'] != null) {
      _userId = result['uid'];
    }
    return response.data;
  }

  Future<void> logout() async {
    try {
      await _dio.post(
        ApiConstants.logout,
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'id': 1,
          'params': {},
        },
      );
    } catch (_) {}
    _sessionId = null;
    _userId = null;
  }

  /// للمستخدمين اللي دخلوا بـ Google — نحفظ الـ partner ID بس
  void setGoogleSession(int partnerId) {
    _userId = partnerId;
    // مش محتاجين session_id لأن العمليات دي بتشتغل بـ public access
  }

  // ─── Create Partner (للـ Google Sign-In) ──────────────────────────────────
  Future<int> createPartner({
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    final result = await callKw(
      model: ApiConstants.resPartner,
      method: 'create',
      args: [
        {
          'name': name,
          'email': email,
          'customer_rank': 1,          // يظهر كعميل في Odoo
          'comment': 'Registered via Google Sign-In on Mobile App',
        }
      ],
    );
    return result as int;
  }

  // ─── Web Signup (للـ Google Sign-In) ──────────────────────────────────────
  Future<bool> webSignup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Get signup page to get CSRF token and set-cookie
      final getResponse = await _dio.get('/web/signup');
      final html = getResponse.data.toString();
      
      // Extract CSRF token
      final csrfMatch = RegExp(r'name="csrf_token"\s+value="([^"]+)"').firstMatch(html);
      if (csrfMatch == null) {
        throw Exception('Could not find CSRF token');
      }
      final csrfToken = csrfMatch.group(1);

      // 2. Submit signup form
      final postResponse = await _dio.post(
        '/web/signup',
        data: {
          'csrf_token': csrfToken,
          'name': name,
          'login': email,
          'password': password,
          'confirm_password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false, // Don't redirect so we can inspect status
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final responseBody = postResponse.data.toString();
      if (responseBody.contains('already exists') || 
          responseBody.contains('already registered') ||
          responseBody.contains('Email already exists')) {
        throw Exception('EMAIL_ALREADY_EXISTS');
      }

      // Check if session cookie was set
      return _sessionId != null;
    } catch (e) {
      if (e.toString().contains('EMAIL_ALREADY_EXISTS')) {
        rethrow;
      }
      return false;
    }
  }

  // ─── Generic call_kw ──────────────────────────────────────────────────────
  Future<dynamic> callKw({
    required String model,
    required String method,
    required List args,
    Map<String, dynamic>? kwargs,
    bool requiresAuth = false,
  }) async {
    final kw = Map<String, dynamic>.from(kwargs ?? {});
    // Add context so Odoo accepts requests with/without full session
    if (!kw.containsKey('context')) {
      kw['context'] = {'website_id': 1, 'lang': 'en_US'};
    }
    final response = await _dio.post(
      ApiConstants.callKw,
      data: {
        'jsonrpc': '2.0',
        'method': 'call',
        'id': DateTime.now().millisecondsSinceEpoch,
        'params': {
          'model': model,
          'method': method,
          'args': args,
          'kwargs': kw,
        },
      },
    );
    if (response.data['error'] != null) {
      final errData = response.data['error'];
      final msg = errData['data']?['message']
                  ?? errData['message']
                  ?? 'Unknown Odoo error';
      // Detect session expiry
      if (msg.toString().toLowerCase().contains('session') ||
          msg.toString().toLowerCase().contains('access') ||
          (errData['data']?['name'] ?? '').toString().contains('SessionExpiredException')) {
        throw Exception('SESSION_EXPIRED');
      }
      throw Exception(msg);
    }
    return response.data['result'];
  }

  // ─── Products ─────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getProducts({
    List? domain,
    int limit = 21,
    int offset = 0,
    String order = 'name asc',
  }) async {
    // Use sale_ok=true to get sellable products; fallback to empty domain if none given
    final effectiveDomain = (domain != null && domain.isNotEmpty)
        ? domain
        : [['sale_ok', '=', true]];
    final result = await callKw(
      model: ApiConstants.productTemplate,
      method: 'search_read',
      args: [effectiveDomain],
      kwargs: {
        'fields': [
          'id', 'name', 'list_price', 'description_sale',
          'image_1024', 'categ_id', 'attribute_line_ids',
          'website_url', 'website_published', 'currency_id',
          'product_variant_ids', 'product_variant_count',
        ],
        'limit': limit,
        'offset': offset,
        'order': order,
      },
    );
    return List<Map<String, dynamic>>.from(result ?? []);
  }

  Future<Map<String, dynamic>> getProductDetail(int productId) async {
    final result = await callKw(
      model: ApiConstants.productTemplate,
      method: 'search_read',
      args: [[['id', '=', productId]]],
      kwargs: {
        'fields': [
          'id', 'name', 'list_price', 'description_sale', 'description',
          'image_1024', 'image_512', 'categ_id', 'attribute_line_ids',
          'website_url', 'currency_id', 'product_variant_ids',
          'product_variant_count', 'qty_available',
        ],
        'limit': 1,
      },
    );
    return (result as List).isNotEmpty ? result[0] : {};
  }

  Future<List<Map<String, dynamic>>> getProductVariants(int templateId) async {
    final result = await callKw(
      model: ApiConstants.productProduct,
      method: 'search_read',
      args: [[['product_tmpl_id', '=', templateId]]],
      kwargs: {
        'fields': [
          'id', 'name', 'list_price', 'image_512',
          'product_template_attribute_value_ids',
          'combination_indices', 'qty_available',
        ],
      },
    );
    return List<Map<String, dynamic>>.from(result ?? []);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final result = await callKw(
        model: ApiConstants.productPublicCategory,
        method: 'search_read',
        args: [[]], // no domain filter - get all public categories
        kwargs: {
          'fields': ['id', 'name', 'image_1024', 'parent_id', 'child_id'],
          'order': 'sequence asc',
          'context': {'website_id': 1, 'lang': 'en_US'},
        },
      );
      return List<Map<String, dynamic>>.from(result ?? []);
    } catch (_) {
      return []; // fallback to static categories in provider
    }
  }

  // ─── Orders ───────────────────────────────────────────────────────────────
  Future<int> createSaleOrder({
    required int partnerId,
    required List<Map<String, dynamic>> orderLines,
    String? note,
  }) async {
    final result = await callKw(
      model: ApiConstants.saleOrder,
      method: 'create',
      args: [
        {
          'partner_id': partnerId,
          'note': note ?? 'Order placed via mobile app - Cash on Delivery',
          'payment_term_id': false,
          'order_line': orderLines.map((line) => [0, 0, line]).toList(),
        }
      ],
    );
    return result as int;
  }

  Future<List<Map<String, dynamic>>> getMyOrders(int partnerId) async {
    final result = await callKw(
      model: ApiConstants.saleOrder,
      method: 'search_read',
      args: [[['partner_id', '=', partnerId]]],
      kwargs: {
        'fields': [
          'id', 'name', 'date_order', 'amount_total',
          'state', 'order_line', 'partner_id', 'currency_id',
        ],
        'order': 'date_order desc',
        'limit': 50,
      },
    );
    return List<Map<String, dynamic>>.from(result ?? []);
  }

  Future<List<Map<String, dynamic>>> getOrderLines(int orderId) async {
    final result = await callKw(
      model: ApiConstants.saleOrderLine,
      method: 'search_read',
      args: [[['order_id', '=', orderId]]],
      kwargs: {
        'fields': [
          'id', 'product_id', 'name', 'product_uom_qty',
          'price_unit', 'price_subtotal',
        ],
      },
    );
    return List<Map<String, dynamic>>.from(result ?? []);
  }

  // ─── Partners ─────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getPartnerInfo(String email) async {
    final result = await callKw(
      model: ApiConstants.resPartner,
      method: 'search_read',
      args: [[['email', '=', email]]],
      kwargs: {
        'fields': ['id', 'name', 'email', 'phone', 'street', 'city', 'country_id'],
        'limit': 1,
      },
    );
    return List<Map<String, dynamic>>.from(result ?? []);
  }

  int? get currentUserId => _userId;
  String? get sessionId => _sessionId;
  void setSession(String sessionId, int userId) {
    _sessionId = sessionId;
    _userId = userId;
  }
}
