import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/odoo_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final OdooService _odoo = OdooService();

  // Google Sign-In config — using your Client ID
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '14802500935-l2jqgnbcd3e2tkrkormmivddb6kmu9g8.apps.googleusercontent.com',
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

  // ─── Google Sign-In ───────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    _isGoogleLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. فتح شاشة اختيار الـ Google Account
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // المستخدم ضغط Cancel
        _isGoogleLoading = false;
        notifyListeners();
        return false;
      }

      final String name = googleUser.displayName ?? googleUser.email.split('@')[0];
      final String email = googleUser.email;
      final String? photoUrl = googleUser.photoUrl;

      // 2. نشوف لو العميل موجود في Odoo
      final existingPartners = await _odoo.getPartnerInfo(email);

      int partnerId = 0;
      int userId = DateTime.now().millisecondsSinceEpoch; // temp ID for Google users

      if (existingPartners.isNotEmpty) {
        // العميل موجود — نستخدم بياناته
        partnerId = existingPartners[0]['id'] as int;
        userId = existingPartners[0]['id'] as int;
      } else {
        // عميل جديد — نسجله في Odoo كـ customer
        partnerId = await _odoo.createPartner(
          name: name,
          email: email,
          photoUrl: photoUrl,
        );
        userId = partnerId;
      }

      _user = AppUser(
        id: userId,
        name: name,
        email: email,
        partnerId: partnerId,
        photoUrl: photoUrl,
        isGoogleUser: true,
      );

      // 3. نعمل session خاص بالـ Google user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_id', 'google_$partnerId');
      await prefs.setInt('user_id', userId);
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', name);
      await prefs.setInt('partner_id', partnerId);
      if (photoUrl != null) await prefs.setString('user_photo', photoUrl);
      await prefs.setBool('is_google_user', true);

      // 4. نخلي الـ OdooService يعرف الـ partner ID
      _odoo.setGoogleSession(partnerId);

      _isGoogleLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Google Sign-In failed. Please try again.';
      _isGoogleLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGoogleUser = prefs.getBool('is_google_user') ?? false;
      if (isGoogleUser) {
        await _googleSignIn.signOut();
      } else {
        await _odoo.logout();
      }
    } catch (_) {}

    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
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
