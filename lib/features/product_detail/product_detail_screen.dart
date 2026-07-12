import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/theme.dart';
import '../../core/providers/product_provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/services/odoo_service.dart';
import '../../core/models/product.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final Map<String, dynamic>? extra;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.extra,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final OdooService _odoo = OdooService();
  Product? _product;
  List<ProductVariant> _variants = [];
  ProductVariant? _selectedVariant;
  int _quantity = 1;
  bool _isLoading = true;
  bool _loadingVariants = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    try {
      // Try to get from provider first
      final product = await context.read<ProductProvider>().getProductById(widget.productId);
      if (product != null) {
        setState(() => _product = product);
        _loadVariants(product.id);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _loadVariants(int templateId) async {
    setState(() => _loadingVariants = true);
    try {
      final data = await _odoo.getProductVariants(templateId);
      setState(() {
        _variants = data.map((j) => ProductVariant.fromJson(j)).toList();
        if (_variants.isNotEmpty) _selectedVariant = _variants.first;
      });
    } catch (_) {}
    setState(() => _loadingVariants = false);
  }

  void _addToCart() {
    final cart = context.read<CartProvider>();
    if (_product == null) return;

    if (_selectedVariant != null) {
      cart.addVariant(_selectedVariant!, _product!, qty: _quantity);
    } else {
      cart.addItem(_product!, qty: _quantity);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_product!.name} added to cart! 🛒'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.extra?['name'] as String? ?? 'Product';
    final imageUrl = widget.extra?['imageUrl'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? _buildLoading()
          : _product == null
              ? _buildError()
              : _buildContent(name, imageUrl),
    );
  }

  Widget _buildLoading() {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceLight,
      highlightColor: AppTheme.cardBorder,
      child: Column(
        children: [
          Container(height: 350, color: AppTheme.surfaceLight),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(height: 24, decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                )),
                const SizedBox(height: 12),
                Container(height: 16, width: 120, decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
          const SizedBox(height: 16),
          const Text('Failed to load product',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _loadProduct, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent(String fallbackName, String? fallbackImage) {
    final product = _product!;
    final price = _selectedVariant?.price ?? product.price;

    return CustomScrollView(
      slivers: [
        // Image App Bar
        SliverAppBar(
          expandedHeight: 350,
          pinned: true,
          backgroundColor: AppTheme.background,
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppTheme.textPrimary, size: 18),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: CachedNetworkImage(
              imageUrl: _selectedVariant?.imageUrl ?? product.imageUrl ?? fallbackImage ?? '',
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppTheme.surfaceLight),
              errorWidget: (_, __, ___) => Container(
                color: AppTheme.surfaceLight,
                child: const Icon(Icons.image_not_supported_outlined,
                    color: AppTheme.textHint, size: 64),
              ),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${price.toStringAsFixed(0)} LE',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (price > 0)
                          const Text(
                            'per piece',
                            style: TextStyle(
                              color: AppTheme.textHint,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                if (product.description != null && product.description!.isNotEmpty) ...[
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Variants
                if (_loadingVariants)
                  const Center(child: CircularProgressIndicator(strokeWidth: 2))
                else if (_variants.isNotEmpty) ...[
                  Text(
                    'Variants (${_variants.length})',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _variants.map((variant) {
                      final isSelected = _selectedVariant?.id == variant.id;
                      // Extract variant name suffix
                      final variantSuffix = variant.name
                          .replaceFirst(product.name, '')
                          .replaceAll(RegExp(r'^\s*\(\s*|\s*\)\s*$'), '')
                          .trim();

                      return GestureDetector(
                        onTap: () => setState(() => _selectedVariant = variant),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.cardBorder,
                            ),
                          ),
                          child: Text(
                            variantSuffix.isEmpty ? variant.name : variantSuffix,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Quantity
                Row(
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: const Icon(Icons.remove,
                                color: AppTheme.textPrimary, size: 18),
                          ),
                          Text(
                            '$_quantity',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _quantity++),
                            icon: const Icon(Icons.add,
                                color: AppTheme.textPrimary, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Add to cart
                Consumer<CartProvider>(
                  builder: (_, cart, __) {
                    final variantId = _selectedVariant?.id ?? product.id;
                    final inCart = cart.hasProduct(variantId);
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _addToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: inCart
                                ? const LinearGradient(
                                    colors: [AppTheme.success, Color(0xFF16A34A)])
                                : AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppTheme.glowShadow,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                inCart
                                    ? Icons.shopping_cart
                                    : Icons.add_shopping_cart,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                inCart ? 'Added to Cart ✓' : 'Add to Cart',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
