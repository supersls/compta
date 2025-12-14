import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/entreprise.dart';

class EntrepriseService {
  Future<List<Entreprise>> getEntreprises() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/entreprise'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Entreprise.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des entreprises');
    }
  }

  Future<Entreprise> getEntreprise(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/entreprise/$id'),
    );

    if (response.statusCode == 200) {
      return Entreprise.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur lors de la récupération de l\'entreprise');
    }
  }

  Future<Entreprise> createEntreprise(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/entreprise'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      return Entreprise.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur lors de la création de l\'entreprise');
    }
  }

  Future<Entreprise> updateEntreprise(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/entreprise/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return Entreprise.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur lors de la mise à jour de l\'entreprise');
    }
  }

  Future<void> deleteEntreprise(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/entreprise/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression de l\'entreprise');
    }
  }
}
