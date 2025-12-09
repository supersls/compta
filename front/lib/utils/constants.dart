/// Constantes de l'application de comptabilité

class AppConstants {
  // Taux de TVA en France
  static const double TVA_NORMALE = 20.0;
  static const double TVA_INTERMEDIAIRE = 10.0;
  static const double TVA_REDUITE = 5.5;
  static const double TVA_PARTICULIERE = 2.1;

  static const List<double> TAUX_TVA = [
    TVA_NORMALE,
    TVA_INTERMEDIAIRE,
    TVA_REDUITE,
    TVA_PARTICULIERE,
  ];

  // Types de factures
  static const String TYPE_VENTE = 'vente';
  static const String TYPE_ACHAT = 'achat';

  // Statuts de factures
  static const String STATUT_EN_ATTENTE = 'en_attente';
  static const String STATUT_PAYEE = 'payee';
  static const String STATUT_PARTIELLEMENT_PAYEE = 'partiellement_payee';
  static const String STATUT_EN_RETARD = 'en_retard';

  // Types d'immobilisations
  static const String IMMOB_MATERIEL = 'materiel';
  static const String IMMOB_VEHICULE = 'vehicule';
  static const String IMMOB_LOGICIEL = 'logiciel';
  static const String IMMOB_IMMOBILIER = 'immobilier';

  // Méthodes d'amortissement
  static const String AMORT_LINEAIRE = 'lineaire';
  static const String AMORT_DEGRESSIF = 'degressif';

  // Coefficients d'amortissement dégressif
  static const double COEF_DEGRESSIF_3_4_ANS = 1.25;
  static const double COEF_DEGRESSIF_5_6_ANS = 1.75;
  static const double COEF_DEGRESSIF_PLUS_6_ANS = 2.25;

  // Journaux comptables
  static const String JOURNAL_VENTES = 'ventes';
  static const String JOURNAL_ACHATS = 'achats';
  static const String JOURNAL_BANQUE = 'banque';
  static const String JOURNAL_OD = 'od'; // Opérations diverses

  // Régimes TVA
  static const String REGIME_REEL_NORMAL = 'reel_normal';
  static const String REGIME_REEL_SIMPLIFIE = 'reel_simplifie';
  static const String REGIME_FRANCHISE = 'franchise';

  // Modes de paiement
  static const String PAIEMENT_VIREMENT = 'virement';
  static const String PAIEMENT_CHEQUE = 'cheque';
  static const String PAIEMENT_ESPECES = 'especes';
  static const String PAIEMENT_CARTE = 'carte';
  static const String PAIEMENT_PRELEVEMENT = 'prelevement';

  // Classes comptables
  static const int CLASSE_CAPITAUX = 1;
  static const int CLASSE_IMMOBILISATIONS = 2;
  static const int CLASSE_STOCKS = 3;
  static const int CLASSE_TIERS = 4;
  static const int CLASSE_FINANCIERS = 5;
  static const int CLASSE_CHARGES = 6;
  static const int CLASSE_PRODUITS = 7;

  // Comptes comptables fréquents
  static const String COMPTE_BANQUE = '512';
  static const String COMPTE_CAISSE = '530';
  static const String COMPTE_CLIENTS = '411';
  static const String COMPTE_FOURNISSEURS = '401';
  static const String COMPTE_TVA_COLLECTEE = '4457';
  static const String COMPTE_TVA_DEDUCTIBLE = '4456';
  static const String COMPTE_VENTES_SERVICES = '706';
  static const String COMPTE_VENTES_MARCHANDISES = '707';
  static const String COMPTE_ACHATS_MARCHANDISES = '607';
  static const String COMPTE_AMORTISSEMENTS = '681';

  // Formats de date
  static const String FORMAT_DATE_FR = 'dd/MM/yyyy';
  static const String FORMAT_DATE_ISO = 'yyyy-MM-dd';
  static const String FORMAT_DATETIME_FR = 'dd/MM/yyyy HH:mm';

  // Paramètres de pagination
  static const int ITEMS_PER_PAGE = 50;

  // Durées de conservation
  static const int DUREE_CONSERVATION_ANNEES = 10;
}
