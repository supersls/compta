class ApiConfig {
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
