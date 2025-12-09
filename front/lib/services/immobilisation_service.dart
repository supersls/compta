import '../services/api_service.dart';
import '../models/immobilisation.dart';

class ImmobilisationService {
  // GET toutes les immobilisations
  Future<List<Immobilisation>> getAllImmobilisations() async {
    final data = await ApiService.get('immobilisations');
    return (data as List).map((item) => Immobilisation.fromMap(item)).toList();
  }

  // POST créer immobilisation
  Future<Immobilisation> createImmobilisation(Immobilisation immobilisation) async {
    final data = await ApiService.post('immobilisations', immobilisation.toMap());
    return Immobilisation.fromMap(data);
  }

  // PUT modifier immobilisation
  Future<Immobilisation> updateImmobilisation(Immobilisation immobilisation) async {
    final data = await ApiService.put(
      'immobilisations/${immobilisation.id}',
      immobilisation.toMap(),
    );
    return Immobilisation.fromMap(data);
  }

  // DELETE supprimer immobilisation
  Future<void> deleteImmobilisation(int id) async {
    await ApiService.delete('immobilisations/$id');
  }

  // POST céder immobilisation
  Future<Immobilisation> cederImmobilisation(
    int id,
    DateTime dateCession,
    double prixCession,
  ) async {
    final data = await ApiService.post('immobilisations/$id/cession', {
      'date_cession': dateCession.toIso8601String().split('T')[0],
      'prix_cession': prixCession,
    });
    return Immobilisation.fromMap(data);
  }

  // GET calcul amortissement pour une année
  Future<Map<String, dynamic>> calculerAmortissement(int id, int annee) async {
    return await ApiService.get('immobilisations/$id/amortissement/$annee');
  }

  // GET tous les amortissements
  Future<List<Map<String, dynamic>>> getAllAmortissements() async {
    final data = await ApiService.get('immobilisations/amortissements');
    return List<Map<String, dynamic>>.from(data);
  }

  // GET amortissements d'une immobilisation
  Future<List<Map<String, dynamic>>> getAmortissementsByImmobilisation(int id) async {
    final data = await ApiService.get('immobilisations/$id/amortissements');
    return List<Map<String, dynamic>>.from(data);
  }

  // POST créer amortissement
  Future<Map<String, dynamic>> createAmortissement(Map<String, dynamic> amortissement) async {
    return await ApiService.post('immobilisations/amortissements', amortissement);
  }

  // GET statistiques
  Future<Map<String, dynamic>> getStatistiques() async {
    return await ApiService.get('immobilisations/statistiques');
  }

  // GET immobilisations par catégorie
  Future<Map<String, dynamic>> getParCategorie() async {
    return await ApiService.get('immobilisations/par-categorie');
  }

  // Calculer plan d'amortissement complet
  List<Map<String, dynamic>> calculerPlanAmortissement(Immobilisation immo) {
    List<Map<String, dynamic>> plan = [];
    double vnc = immo.valeurAcquisition;
    final dateDebut = immo.dateAcquisition;

    for (int i = 1; i <= immo.dureeAmortissement; i++) {
      double dotation;
      
      if (immo.methodeAmortissement == 'lineaire') {
        // Amortissement linéaire
        dotation = immo.valeurAcquisition / immo.dureeAmortissement;
        
        // Prorata temporis la première année
        if (i == 1 && dateDebut.month != 1) {
          final moisRestants = 13 - dateDebut.month;
          dotation = (dotation * moisRestants) / 12;
        }
      } else {
        // Amortissement dégressif
        final taux = immo.tauxAmortissementCalcule;
        dotation = vnc * (taux / 100);
        
        // Prorata temporis la première année
        if (i == 1 && dateDebut.month != 1) {
          final moisRestants = 13 - dateDebut.month;
          dotation = (dotation * moisRestants) / 12;
        }
        
        // Passage au linéaire si plus avantageux
        final dotationLineaire = vnc / (immo.dureeAmortissement - i + 1);
        if (dotationLineaire > dotation) {
          dotation = dotationLineaire;
        }
      }

      vnc = (vnc - dotation).clamp(0, double.infinity);
      
      plan.add({
        'annee': dateDebut.year + i - 1,
        'dotation': dotation,
        'vnc': vnc,
        'cumul': immo.valeurAcquisition - vnc,
      });
    }

    return plan;
  }
}
