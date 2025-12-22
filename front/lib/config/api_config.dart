class ApiConfig {
  // Change this to your EC2 IP or domain for production
  // Example: 'http://3.123.45.67:3000/api' or 'https://api.yourdomain.com/api'
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Endpoints
  static const String factures = '$baseUrl/factures';
  static const String tva = '$baseUrl/tva';
  static const String banque = '$baseUrl/banque';
  static const String immobilisations = '$baseUrl/immobilisations';
  static const String comptabilite = '$baseUrl/comptabilite';
  static const String entreprise = '$baseUrl/entreprise';
  
  // Timeout
  static const Duration timeout = Duration(seconds: 30);
}
