import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/odoo_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final OdooService _odoo = OdooService();

  // Google Sign-In — للأندرويد الـ SHA-1 بيشتغل تلقائي بدون clientId
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AppUser? _user;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  bool get isGoogleLoading => _isGoogleLoading;
  String? get errorMessage => _errorMessage;
  bool get initialized => _initialized;

  AuthProvider() {
    _odoo.init();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('session_id');
    final userId = prefs.getInt('user_id');
    final userEmail = prefs.getString('user_email');
    final userName = prefs.getString('user_name');
    final partnerId = prefs.getInt('partner_id');
    final userPhoto = prefs.getString('user_photo');

    if (sessionId != null && userId != null && userEmail != null) {
      _odoo.setSession(sessionId, userId);
      _user = AppUser(
        id: userId,
        name: userName ?? 'User',
        email: userEmail,
        partnerId: partnerId ?? 0,
        photoUrl: userPhoto,
      );
    }
    _initialized = true;
    notifyListeners();
  }

  // ─── Email/Password Login ─────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _odoo.authenticate(email, password);
      final result = response['result'];

      if (result == null || result['uid'] == null) {
        _errorMessage = 'Invalid email or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      int partnerId = 0;
      if (result['partner_id'] != null) {
        partnerId = result['partner_id'] as int;
      } else {
        final partners = await _odoo.getPartnerInfo(email);
        partnerId = partners.isNotEmpty ? partners[0]['id'] as int : 0;
      }

      _user = AppUser(
        id: result['uid'] as int,
        name: result['name'] as String? ?? email,
        email: email,
        partnerId: partnerId,
      );

      await _saveSession(partnerId: partnerId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Obfuscated Deterministic Password Generator for Google users ──────────
  String _generateGoogleUserPassword(String email) {
    final salt = 'edu_manufacturing_app_salt_2026';
    final input = '$email$salt';
    int hash1 = 5381;
    int hash2 = 89;
    for (int i = 0; i < input.length; i++) {
      final char = input.codeUnitAt(i);
      hash1 = ((hash1 << 5) + hash1) + char;
      hash2 = ((hash2 << 5) + hash2) ^ char;
    }
    return 'GoogleUser_${hash1.abs()}_${hash2.abs()}!';
  }

  // ─── Google Sign-In ───────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    _isGoogleLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. فتح شاشة اختيار الـ Google Account
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isGoogleLoading = false;
        notifyListeners();
        return false;
      }

      final String name = googleUser.displayName ?? googleUser.email.split('@')[0];
      final String email = googleUser.email;
      final String? photoUrl = googleUser.photoUrl;

      // توليد كلمة سر فريدة وقوية خاصة بالمستخدم بناء على إيميله
      final generatedPassword = _generateGoogleUserPassword(email);

      bool isAuthenticated = false;

      // 2. نحاول نسجل دخول بالـ Google-specific password أولاً
      try {
        final response = await _odoo.authenticate(email, generatedPassword);
        final result = response['result'];
        if (result != null && result['uid'] != null) {
          isAuthenticated = true;
        }
      } catch (_) {
        // لو فشل الدخول، معناه إن المستخدم جديد تماماً أو مسجل بباسوورد يدوي
      }

      if (!isAuthenticated) {
        // 3. نحاول نعمل signup للمستخدم الجديد
        try {
          final signupSuccess = await _odoo.webSignup(
            name: name,
            email: email,
            password: generatedPassword,
          );

          if (signupSuccess) {
            // بعد الـ signup الناجح، بنعمل authenticate للحصول على الـ session_id والـ uid
            final authResponse = await _odoo.authenticate(email, generatedPassword);
            final result = authResponse['result'];
            if (result == null || result['uid'] == null) {
              throw Exception('Authentication failed after signup');
            }
          }
        } catch (signupError) {
          // لو فشل الـ signup لأن الإيميل مسجل مسبقاً بباسوورد يدوي على الويب سايت
          if (signupError.toString().contains('EMAIL_ALREADY_EXISTS')) {
            _errorMessage = 'This email is already registered on the website. Please log in with your email and password.';
            _isGoogleLoading = false;
            notifyListeners();
            return false;
          } else {
            rethrow;
          }
        }
      }

      // 4. جلب الـ Partner ID الخاص بالمستخدم المسجل
      final partners = await _odoo.getPartnerInfo(email);
      if (partners.isEmpty) {
        throw Exception('User authenticated but partner record not found');
      }

      final int partnerId = partners[0]['id'] as int;
      final int userId = partners[0]['id'] as int;

      _user = AppUser(
        id: userId,
        name: name,
        email: email,
        partnerId: partnerId,
        photoUrl: photoUrl,
        isGoogleUser: true,
      );

      // 5. حفظ الـ session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_id', _odoo.sessionId ?? '');
      await prefs.setInt('user_id', userId);
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', name);
      await prefs.setInt('partner_id', partnerId);
      if (photoUrl != null) await prefs.setString('user_photo', photoUrl);
      await prefs.setBool('is_google_user', true);

      _isGoogleLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Google Sign-In failed: $e';
      _isGoogleLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final isGoogleUser = prefs.getBool('is_google_user') ?? false;

    // 1. Clear local state and notify listeners immediately for instant UI response
    _user = null;
    notifyListeners();

    // 2. Clear local storage in background
    await prefs.clear();

    // 3. Trigger external logout/signOut in background without blocking UI transition
    try {
      if (isGoogleUser) {
        _googleSignIn.signOut().catchError((_) => null);
      } else {
        _odoo.logout().catchError((_) => null);
      }
    } catch (_) {}
  }

  Future<void> _saveSession({required int partnerId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_id', _odoo.sessionId ?? '');
    await prefs.setInt('user_id', _user!.id);
    await prefs.setString('user_email', _user!.email);
    await prefs.setString('user_name', _user!.name);
    await prefs.setInt('partner_id', partnerId);
    await prefs.setBool('is_google_user', false);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
