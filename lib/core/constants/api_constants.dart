class ApiConstants {
  static const String baseUrl = 'https://edu-manufacturing-general.odoo.com';
  static const String db = 'edu-manufacturing-general';

  // ─── Auth ─────────────────────────────────────────────────────────────────
  static const String authenticate = '/web/session/authenticate';
  static const String logout = '/web/session/destroy';
  static const String signup = '/web/auth/sign_up';

  // ─── Dataset ──────────────────────────────────────────────────────────────
  static const String callKw = '/web/dataset/call_kw';
  static const String callButton = '/web/dataset/call_button';

  // ─── Shop ─────────────────────────────────────────────────────────────────
  static const String shop = '/shop';
  static const String cartUpdate = '/shop/cart/update';
  static const String cartQuantity = '/shop/cart/update_json';
  static const String checkout = '/shop/checkout';

  // ─── Models ───────────────────────────────────────────────────────────────
  static const String productTemplate = 'product.template';
  static const String productProduct = 'product.product';
  static const String saleOrder = 'sale.order';
  static const String saleOrderLine = 'sale.order.line';
  static const String resPartner = 'res.partner';
  static const String productCategory = 'product.category';
  static const String productPublicCategory = 'product.public.category';

  // ─── Image URLs ───────────────────────────────────────────────────────────
  static String productImageUrl(int productId, {String size = '512'}) =>
      '$baseUrl/web/image/product.product/$productId/image_$size';

  static String templateImageUrl(int templateId, {String size = '512'}) =>
      '$baseUrl/web/image/product.template/$templateId/image_$size';
}
