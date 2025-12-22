import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadToken();
  }

  // Load token from storage
  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      
      if (_token != null) {
        await _verifyToken();
      }
      notifyListeners();
    } catch (e) {
      print('Erreur chargement token: $e');
    }
  }

  // Verify token validity
  Future<bool> _verifyToken() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': _token}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = data['user'];
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      print('Erreur vérification token: $e');
      return false;
    }
  }

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _user = data['user'];

        // Save token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);

        notifyListeners();
        return true;
      } else {
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Erreur login: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    print('🔓 Logout called');
    _token = null;
    _user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    
    print('🔓 Token cleared, notifying listeners');
    notifyListeners();
  }
}
