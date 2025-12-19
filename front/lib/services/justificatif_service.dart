import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/api_config.dart';

class JustificatifService {
  final String baseUrl = '${ApiConfig.baseUrl}/justificatifs';

  /// Upload un justificatif
  Future<Map<String, dynamic>> uploadJustificatif(
    dynamic file, {
    String? description,
    String? typeDocument,
    DateTime? dateDocument,
    int? factureId,
    int? ecritureId,
    int? clientId,
    String? fileName,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

      // Ajouter le fichier
      if (kIsWeb) {
        // Sur web, file est de type PlatformFile avec bytes
        if (file.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: fileName ?? file.name,
          ));
        }
      } else {
        // Sur mobile/desktop, file est de type File
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      // Ajouter les métadonnées
      if (description != null) request.fields['description'] = description;
      if (typeDocument != null) request.fields['type_document'] = typeDocument;
      if (dateDocument != null) {
        request.fields['date_document'] = dateDocument.toIso8601String().split('T')[0];
      }
      if (factureId != null) request.fields['facture_id'] = factureId.toString();
      if (ecritureId != null) request.fields['ecriture_id'] = ecritureId.toString();
      if (clientId != null) request.fields['client_id'] = clientId.toString();

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de l\'upload: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'upload du justificatif: $e');
    }
  }

  /// Récupère la liste des justificatifs
  Future<List<Map<String, dynamic>>> getJustificatifs({
    String? typeDocument,
    int? factureId,
    int? clientId,
    bool? archive,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (typeDocument != null) queryParams['type_document'] = typeDocument;
      if (factureId != null) queryParams['facture_id'] = factureId.toString();
      if (clientId != null) queryParams['client_id'] = clientId.toString();
      if (archive != null) queryParams['archive'] = archive.toString();

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['justificatifs']);
      } else {
        throw Exception('Erreur lors de la récupération des justificatifs');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Télécharge un justificatif
  Future<List<int>> downloadJustificatif(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id/download'));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Erreur lors du téléchargement');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Obtient l'URL de visualisation
  String getViewUrl(int id) {
    return '$baseUrl/$id/view';
  }

  /// Supprime un justificatif
  Future<void> deleteJustificatif(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Archive un justificatif
  Future<void> archiveJustificatif(int id) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/$id/archive'));

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de l\'archivage');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Met à jour les métadonnées
  Future<void> updateJustificatif(
    int id, {
    String? description,
    String? typeDocument,
    DateTime? dateDocument,
    int? factureId,
    int? ecritureId,
    int? clientId,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (description != null) body['description'] = description;
      if (typeDocument != null) body['type_document'] = typeDocument;
      if (dateDocument != null) {
        body['date_document'] = dateDocument.toIso8601String().split('T')[0];
      }
      if (factureId != null) body['facture_id'] = factureId;
      if (ecritureId != null) body['ecriture_id'] = ecritureId;
      if (clientId != null) body['client_id'] = clientId;

      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la mise à jour');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }
}
