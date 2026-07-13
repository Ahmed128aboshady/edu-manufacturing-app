import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../app/theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/models/product.dart';
import '../shop/widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>()
        ..loadCategories()
        ..loadProducts(refresh: true);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final userName = (user != null && user.name.isNotEmpty)
        ? user.name.split(' ').first
        : 'User';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $userName 👋',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Find your style',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notification/search button
                    GestureDetector(
                      onTap: () => context.go('/shop'),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: const Icon(Icons.search,
                            color: AppTheme.textPrimary, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Hero Banner
            SliverToBoxAdapter(child: _buildHeroBanner()),

            // Categories
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _buildCategories(),
                ],
              ),
            ),

            // Featured Products
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured Products',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Products grid
            _buildProductsGrid(),

            // See all
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: OutlinedButton(
                  onPressed: () => context.go('/shop'),
                  child: const Text('See All Products'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    final banners = [
      _PromoBanner(
        title: 'Summer 2025\nCollection',
        subtitle: '🔥 New Collection',
        cta: 'Shop Now →',
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF9C4DCC)],
        ),
        onTap: () => context.go('/shop'),
      ),
      _PromoBanner(
        title: '50% OFF on\nBasic T-Shirt!',
        subtitle: '⚡ Special Offer',
        cta: 'Claim Offer →',
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6584), Color(0xFFF59E0B)],
        ),
        onTap: () {
          context.read<ProductProvider>().setSearchQuery('T-Shirt');
          context.go('/shop');
        },
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: banner.gradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.glowShadow,
                ),
                child: Stack(
                  children: [
                    // Background decorations
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      bottom: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              banner.subtitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            banner.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: banner.onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                banner.cta,
                                style: const TextStyle(
                                  color: AppTheme.primaryDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SmoothPageIndicator(
          controller: _pageController,
          count: banners.length,
          effect: const ExpandingDotsEffect(
            activeDotColor: AppTheme.primary,
            dotColor: AppTheme.cardBorder,
            dotHeight: 6,
            dotWidth: 6,
            expansionFactor: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return Consumer<ProductProvider>(
      builder: (_, provider, __) {
        // Static categories from website scan
        final categories = [
          _CategoryData(id: 1, name: 'Men', emoji: '👔'),
          _CategoryData(id: 2, name: 'Women', emoji: '👗'),
          _CategoryData(id: 3, name: 'Kids', emoji: '🧒'),
          _CategoryData(id: 0, name: 'All', emoji: '🛍️'),
        ];

        return SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              return GestureDetector(
                onTap: () {
                  context.read<ProductProvider>().setCategory(
                    cat.id == 0 ? null : cat.id,
                  );
                  context.go('/shop');
                },
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    gradient: i == 0 ? AppTheme.primaryGradient : null,
                    color: i != 0 ? AppTheme.surfaceLight : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(
                        cat.name,
                        style: TextStyle(
                          color: i == 0 ? Colors.white : AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductsGrid() {
    return Consumer<ProductProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading && provider.products.isEmpty) {
          return SliverToBoxAdapter(child: _buildLoadingGrid());
        }

        if (provider.products.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'No products found',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          );
        }

        final featured = provider.products.take(6).toList();

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => ProductCard(product: featured[i]),
              childCount: featured.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: AppTheme.surfaceLight,
          highlightColor: AppTheme.cardBorder,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryData {
  final int id;
  final String name;
  final String emoji;
  const _CategoryData({required this.id, required this.name, required this.emoji});
}

class _PromoBanner {
  final String title;
  final String subtitle;
  final String cta;
  final Gradient gradient;
  final VoidCallback onTap;
  const _PromoBanner({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.gradient,
    required this.onTap,
  });
}
