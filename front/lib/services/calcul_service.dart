import '../utils/constants.dart';

class CalculService {
  /// Calcule la TVA sur un montant HT
  static double calculerTVA(double montantHT, double tauxTVA) {
    return _arrondir(montantHT * tauxTVA / 100);
  }

  /// Calcule le montant TTC à partir d'un montant HT
  static double calculerTTC(double montantHT, double tauxTVA) {
    final tva = calculerTVA(montantHT, tauxTVA);
    return _arrondir(montantHT + tva);
  }

  /// Récupère le montant HT à partir d'un montant TTC
  static double montantHTDepuisTTC(double montantTTC, double tauxTVA) {
    return _arrondir(montantTTC / (1 + tauxTVA / 100));
  }

  /// Récupère la TVA à partir d'un montant TTC
  static double tvaDepuisTTC(double montantTTC, double tauxTVA) {
    final montantHT = montantHTDepuisTTC(montantTTC, tauxTVA);
    return _arrondir(montantTTC - montantHT);
  }

  /// Calcule l'amortissement linéaire pour une année donnée
  static double calculerAmortissementLineaire({
    required double valeurAcquisition,
    required int dureeAnnees,
    required int anneeEnCours,
    required DateTime dateAcquisition,
  }) {
    final tauxAmortissement = 100 / dureeAnnees;
    final amortissementAnnuel = valeurAcquisition * tauxAmortissement / 100;

    // Prorata temporis pour la première année
    if (anneeEnCours == dateAcquisition.year) {
      final joursRestants = DateTime(dateAcquisition.year, 12, 31)
          .difference(dateAcquisition)
          .inDays + 1;
      return _arrondir(amortissementAnnuel * joursRestants / 365);
    }

    return _arrondir(amortissementAnnuel);
  }

  /// Calcule l'amortissement dégressif pour une année donnée
  static double calculerAmortissementDegressif({
    required double valeurAcquisition,
    required int dureeAnnees,
    required double vncDebut,
    required int anneeDepuisAcquisition,
  }) {
    // Coefficient dégressif selon la durée
    final coefficient = _getCoefficientDegressif(dureeAnnees);
    final tauxDegressif = (100 / dureeAnnees) * coefficient;

    // Calcul amortissement dégressif
    final amortissementDegressif = vncDebut * tauxDegressif / 100;

    // Calcul amortissement linéaire sur durée restante
    final anneesRestantes = dureeAnnees - anneeDepuisAcquisition + 1;
    final amortissementLineaire = anneesRestantes > 0 
        ? vncDebut / anneesRestantes 
        : 0;

    // Basculement vers linéaire si plus avantageux
    return _arrondir(
      amortissementDegressif > amortissementLineaire
          ? amortissementDegressif
          : amortissementLineaire
    );
  }

  /// Retourne le coefficient dégressif selon la durée
  static double _getCoefficientDegressif(int dureeAnnees) {
    if (dureeAnnees >= 6) {
      return AppConstants.COEF_DEGRESSIF_PLUS_6_ANS;
    } else if (dureeAnnees >= 5) {
      return AppConstants.COEF_DEGRESSIF_5_6_ANS;
    } else {
      return AppConstants.COEF_DEGRESSIF_3_4_ANS;
    }
  }

  /// Calcule le plan d'amortissement complet
  static List<Map<String, dynamic>> calculerPlanAmortissement({
    required double valeurAcquisition,
    required int dureeAnnees,
    required DateTime dateAcquisition,
    required String methode,
    double valeurResiduelle = 0,
  }) {
    final plan = <Map<String, dynamic>>[];
    double cumulAmortissements = 0;
    double vnc = valeurAcquisition;

    for (int i = 1; i <= dureeAnnees; i++) {
      final annee = dateAcquisition.year + i - 1;
      double amortissement;

      if (methode == AppConstants.AMORT_LINEAIRE) {
        amortissement = calculerAmortissementLineaire(
          valeurAcquisition: valeurAcquisition,
          dureeAnnees: dureeAnnees,
          anneeEnCours: annee,
          dateAcquisition: dateAcquisition,
        );
      } else {
        amortissement = calculerAmortissementDegressif(
          valeurAcquisition: valeurAcquisition,
          dureeAnnees: dureeAnnees,
          vncDebut: vnc,
          anneeDepuisAcquisition: i,
        );
      }

      cumulAmortissements = _arrondir(cumulAmortissements + amortissement);
      vnc = _arrondir(valeurAcquisition - cumulAmortissements);

      // S'assurer que la VNC ne descend pas sous la valeur résiduelle
      if (vnc < valeurResiduelle) {
        amortissement = _arrondir(amortissement - (valeurResiduelle - vnc));
        vnc = valeurResiduelle;
        cumulAmortissements = _arrondir(valeurAcquisition - valeurResiduelle);
      }

      plan.add({
        'exercice': i,
        'annee': annee,
        'montant_amortissement': amortissement,
        'cumul_amortissements': cumulAmortissements,
        'valeur_nette_comptable': vnc,
      });

      // Arrêter si on a atteint la valeur résiduelle
      if (vnc <= valeurResiduelle) break;
    }

    return plan;
  }

  /// Calcule le résultat net (produits - charges)
  static double calculerResultatNet(double produits, double charges) {
    return _arrondir(produits - charges);
  }

  /// Calcule le taux de marge
  static double calculerTauxMarge(double produits, double charges) {
    if (produits == 0) return 0;
    return _arrondir((produits - charges) / produits * 100);
  }

  /// Calcule la rentabilité
  static double calculerRentabilite(double benefice, double ca) {
    if (ca == 0) return 0;
    return _arrondir(benefice / ca * 100);
  }

  /// Arrondit à 2 décimales
  static double _arrondir(num montant) {
    return (montant * 100).round() / 100;
  }

  /// Calcule le prorata temporis en jours
  static int calculerProrataJours(DateTime debut, DateTime fin) {
    return fin.difference(debut).inDays + 1;
  }

  /// Calcule le prorata temporis en pourcentage annuel
  static double calculerProrataPourcentage(DateTime debut, DateTime fin) {
    final jours = calculerProrataJours(debut, fin);
    final annee = debut.year;
    final joursAnnee = DateTime(annee, 12, 31).difference(DateTime(annee, 1, 1)).inDays + 1;
    return _arrondir(jours / joursAnnee * 100);
  }

  /// Vérifie si une écriture comptable est équilibrée
  static bool estEquilibree(double debit, double credit) {
    return (debit - credit).abs() < 0.01;
  }

  /// Calcule le solde d'un compte (débit - crédit pour actif/charge, crédit - débit pour passif/produit)
  static double calculerSoldeCompte(double debit, double credit, String typeCompte) {
    if (typeCompte == 'actif' || typeCompte == 'charge') {
      return _arrondir(debit - credit);
    } else {
      return _arrondir(credit - debit);
    }
  }
}
