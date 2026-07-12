import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/odoo_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final OdooService _odoo = OdooService();

  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
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

    if (sessionId != null && userId != null && userEmail != null) {
      _odoo.setSession(sessionId, userId);
      _user = AppUser(
        id: userId,
        name: userName ?? 'User',
        email: userEmail,
        partnerId: partnerId ?? 0,
      );
    }
    _initialized = true;
    notifyListeners();
  }

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

      // Get partner info
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

      // Save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_id', _odoo.sessionId ?? '');
      await prefs.setInt('user_id', _user!.id);
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', _user!.name);
      await prefs.setInt('partner_id', partnerId);

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

  Future<void> logout() async {
    try {
      await _odoo.logout();
    } catch (_) {}

    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
