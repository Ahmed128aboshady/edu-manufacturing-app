# edu-Manufacturing Flutter App

تطبيق موبايل لمتجر edu-Manufacturing-General على Odoo مبني بـ Flutter.

## 📱 الشاشات

| الشاشة | الوظيفة |
|--------|---------|
| **Splash** | شاشة البداية مع التحقق من الجلسة |
| **Login** | تسجيل الدخول بـ Odoo JSON-RPC |
| **Home** | الصفحة الرئيسية مع التصنيفات والمنتجات |
| **Shop** | تصفح كل المنتجات مع البحث والفلترة |
| **Product Detail** | تفاصيل المنتج + اختيار الـ variant |
| **Cart** | سلة التسوق مع تعديل الكميات |
| **Checkout** | تأكيد الطلب (دفع عند الاستلام) |
| **My Orders** | طلباتي من قاعدة بيانات Odoo |
| **Profile** | بيانات المستخدم + تسجيل الخروج |

## 🔌 ربط Odoo API

- **Auth:** `POST /web/session/authenticate`
- **Products:** `POST /web/dataset/call_kw` → `product.template`
- **Orders (إنشاء):** `POST /web/dataset/call_kw` → `sale.order.create`
- **Orders (قراءة):** `POST /web/dataset/call_kw` → `sale.order.search_read`

## 🚀 كيفية التشغيل

### المتطلبات
```
Flutter SDK >= 3.2.0
Dart SDK >= 3.2.0
Android SDK (للـ Android)
Xcode (للـ iOS - على Mac)
```

### التثبيت
```bash
flutter pub get
flutter run
```

### Build للنشر
```bash
# Android APK
flutter build apk --release

# Android App Bundle (للـ Play Store)
flutter build appbundle --release

# iOS (على Mac فقط)
flutter build ios --release
```

## 📁 هيكل المجلدات

```
lib/
├── main.dart                    # نقطة الدخول
├── app/
│   ├── app.dart                 # Root widget
│   ├── router.dart              # GoRouter navigation
│   └── theme.dart               # Dark theme + colors
├── core/
│   ├── constants/
│   │   └── api_constants.dart   # Odoo API endpoints
│   ├── services/
│   │   └── odoo_service.dart    # JSON-RPC client
│   ├── models/
│   │   ├── product.dart
│   │   ├── order.dart
│   │   ├── cart_item.dart
│   │   └── user.dart
│   └── providers/
│       ├── auth_provider.dart
│       ├── cart_provider.dart
│       ├── product_provider.dart
│       └── order_provider.dart
└── features/
    ├── splash/
    ├── auth/
    ├── home/
    ├── shop/
    ├── product_detail/
    ├── cart/
    ├── checkout/
    ├── orders/
    ├── profile/
    └── main/
```

## 🎨 التصميم

- **Theme:** Dark Mode
- **Primary Color:** `#6C63FF` (Indigo/Purple)
- **Font:** Google Fonts - Outfit
- **Style:** Glassmorphism + Gradient cards

## 📞 بيانات الموقع

- **URL:** https://edu-manufacturing-general.odoo.com
- **التصنيفات:** Men / Women / Kids
- **العملة:** جنيه مصري (LE)
- **الدفع:** عند الاستلام (COD)
