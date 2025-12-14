import 'package:flutter/material.dart';
import '../models/entreprise.dart';
import '../services/entreprise_service.dart';

class EntrepriseProvider extends ChangeNotifier {
  Entreprise? _selectedEntreprise;
  List<Entreprise> _entreprises = [];
  bool _isLoading = false;
  final EntrepriseService _service = EntrepriseService();

  Entreprise? get selectedEntreprise => _selectedEntreprise;
  List<Entreprise> get entreprises => _entreprises;
  bool get isLoading => _isLoading;

  void selectEntreprise(Entreprise entreprise) {
    _selectedEntreprise = entreprise;
    notifyListeners();
  }

  void clearSelection() {
    _selectedEntreprise = null;
    notifyListeners();
  }

  Future<void> loadEntreprises() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _entreprises = await _service.getEntreprises();
      
      // Sélectionner la première entreprise par défaut si aucune n'est sélectionnée
      if (_selectedEntreprise == null && _entreprises.isNotEmpty) {
        _selectedEntreprise = _entreprises.first;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Erreur lors du chargement des entreprises: $e');
      rethrow;
    }
  }

  Future<void> loadEntreprise(int id) async {
    try {
      _selectedEntreprise = await _service.getEntreprise(id);
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement de l\'entreprise: $e');
      rethrow;
    }
  }
}
