import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/auth_provider.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/shop/shop_screen.dart';
import '../features/product_detail/product_detail_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/main/main_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/splash',
      // تم إلغاء الـ refreshListenable والـ redirect التلقائي لتجنب التضاربات مع حركات الملاحة والـ Dialogs
      // الملاحة تتم الآن بشكل صريح (Explicit) ومستقر 100%
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (_, __) => const SignupScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainScreen(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, __) => const HomeScreen(),
            ),
            GoRoute(
              path: '/shop',
              builder: (_, __) => const ShopScreen(),
            ),
            GoRoute(
              path: '/cart',
              builder: (_, __) => const CartScreen(),
            ),
            GoRoute(
              path: '/orders',
              builder: (_, __) => const OrdersScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/product/:id',
          builder: (context, state) {
            final productId = int.parse(state.pathParameters['id']!);
            final extra = state.extra as Map<String, dynamic>?;
            return ProductDetailScreen(
              productId: productId,
              extra: extra,
            );
          },
        ),
        GoRoute(
          path: '/checkout',
          builder: (_, __) => const CheckoutScreen(),
        ),
      ],
    );
  }
}
