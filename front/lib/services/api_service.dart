import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  // GET request
  static Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}/$endpoint');
      
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())));
      }
      
      final response = await http
          .get(
            uri,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH request
  static Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  static Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/$endpoint'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Download file (PDF/Excel)
  static Future<void> downloadFile(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}/$endpoint');
      
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())));
      }
      
      // Pour le web, on ouvre simplement l'URL dans un nouvel onglet
      // Le navigateur gèrera automatiquement le téléchargement
      // ignore: avoid_web_libraries_in_flutter
      // import 'dart:html' as html;
      // html.window.open(uri.toString(), '_blank');
      
      // Pour l'instant, on lance juste la requête
      await http.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Handle HTTP response
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw ApiException(
        statusCode: response.statusCode,
        message: error['error'] ?? 'Erreur serveur',
      );
    }
  }

  // Handle errors
  static Exception _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    } else if (error.toString().contains('TimeoutException')) {
      return ApiException(
        statusCode: 408,
        message: 'Délai d\'attente dépassé',
      );
    } else if (error.toString().contains('SocketException')) {
      return ApiException(
        statusCode: 503,
        message: 'Impossible de se connecter au serveur',
      );
    } else {
      return ApiException(
        statusCode: 500,
        message: 'Erreur: ${error.toString()}',
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}
