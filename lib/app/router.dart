import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

// تعريف مفتاح ملاحة جذري فريد وعالمي (Global Root Navigator Key)
// هذا يمنع تداخلات الملاحة وتضارب الـ ShellRoute مع المسارات الجذرية (مثل تسجيل الدخول)
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Navigation Routing Error',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  state.error?.toString() ?? 'Unknown routing error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => router.go('/login'),
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: rootNavigatorKey, // توجيه المسار للملاحة الجذرية خارج الـ Shell
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: rootNavigatorKey, // توجيه المسار للملاحة الجذرية خارج الـ Shell
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        parentNavigatorKey: rootNavigatorKey, // توجيه المسار للملاحة الجذرية خارج الـ Shell
        builder: (_, __) => const SignupScreen(),
      ),
      ShellRoute(
        // لا نحدد له parentNavigatorKey لأننا نريده كشريط تبويبات سفلي فرعي
        builder: (context, state, child) => MainScreen(
          child: child,
          location: state.matchedLocation,
        ),
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
        parentNavigatorKey: rootNavigatorKey, // يفتح فوق شريط التبويبات بالكامل
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
        parentNavigatorKey: rootNavigatorKey, // يفتح فوق شريط التبويبات بالكامل
        builder: (_, __) => const CheckoutScreen(),
      ),
    ],
  );
}
