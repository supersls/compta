class Immobilisation {
  final int? id;
  final String libelle;
  final String type; // materiel, vehicule, logiciel, immobilier
  final DateTime dateAcquisition;
  final double valeurAcquisition;
  final int dureeAmortissement; // en années
  final String methodeAmortissement; // lineaire, degressif
  final double? tauxAmortissement;
  final double valeurResiduelle;
  final String? compteImmobilisation;
  final String? compteAmortissement;
  final bool enService;
  final DateTime? dateCession;
  final String? notes;
  final DateTime createdAt;

  Immobilisation({
    this.id,
    required this.libelle,
    required this.type,
    required this.dateAcquisition,
    required this.valeurAcquisition,
    required this.dureeAmortissement,
    this.methodeAmortissement = 'lineaire',
    this.tauxAmortissement,
    this.valeurResiduelle = 0,
    this.compteImmobilisation,
    this.compteAmortissement,
    this.enService = true,
    this.dateCession,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'libelle': libelle,
      'type': type,
      'date_acquisition': dateAcquisition.toIso8601String(),
      'valeur_acquisition': valeurAcquisition,
      'duree_amortissement': dureeAmortissement,
      'methode_amortissement': methodeAmortissement,
      'taux_amortissement': tauxAmortissement,
      'valeur_residuelle': valeurResiduelle,
      'compte_immobilisation': compteImmobilisation,
      'compte_amortissement': compteAmortissement,
      'en_service': enService ? 1 : 0,
      'date_cession': dateCession?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Immobilisation.fromMap(Map<String, dynamic> map) {
    // Helper to convert to double
    double _toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    // Helper to convert to int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    return Immobilisation(
      id: map['id'],
      libelle: map['libelle'] ?? map['designation'] ?? '',
      type: map['type'] ?? map['categorie'] ?? '',
      dateAcquisition: map['date_acquisition'] is String
          ? DateTime.parse(map['date_acquisition'])
          : (map['date_acquisition'] as DateTime?) ?? DateTime.now(),
      valeurAcquisition: _toDouble(map['valeur_acquisition']),
      dureeAmortissement: _toInt(map['duree_amortissement']),
      methodeAmortissement: map['methode_amortissement'] ?? 'lineaire',
      tauxAmortissement: map['taux_amortissement'] != null
          ? _toDouble(map['taux_amortissement'])
          : null,
      valeurResiduelle: map['valeur_residuelle'] != null
          ? _toDouble(map['valeur_residuelle'])
          : (map['valeur_nette_comptable'] != null
              ? _toDouble(map['valeur_nette_comptable'])
              : 0),
      compteImmobilisation: map['compte_immobilisation'],
      compteAmortissement: map['compte_amortissement'],
      enService: map['en_service'] == 1 || map['en_service'] == true,
      dateCession: map['date_cession'] != null
          ? (map['date_cession'] is String
              ? DateTime.parse(map['date_cession'])
              : map['date_cession'] as DateTime)
          : null,
      notes: map['notes'],
      createdAt: map['created_at'] != null
          ? (map['created_at'] is String
              ? DateTime.parse(map['created_at'])
              : map['created_at'] as DateTime)
          : (map['date_creation'] != null
              ? (map['date_creation'] is String
                  ? DateTime.parse(map['date_creation'])
                  : map['date_creation'] as DateTime)
              : DateTime.now()),
    );
  }

  double get tauxAmortissementCalcule {
    if (tauxAmortissement != null) return tauxAmortissement!;
    if (methodeAmortissement == 'lineaire') {
      return 100 / dureeAmortissement;
    }
    // Dégressif
    double tauxLineaire = 100 / dureeAmortissement;
    if (dureeAmortissement <= 3) return tauxLineaire * 1.25;
    if (dureeAmortissement <= 5) return tauxLineaire * 1.75;
    return tauxLineaire * 2.25;
  }

  double get totalAmorti => valeurAcquisition - valeurResiduelle;

  double get pourcentageAmorti {
    if (valeurAcquisition == 0) return 0;
    return (totalAmorti / valeurAcquisition) * 100;
  }

  int get anneesRestantes {
    final now = DateTime.now();
    final anneesEcoulees = now.year - dateAcquisition.year;
    return (dureeAmortissement - anneesEcoulees).clamp(0, dureeAmortissement);
  }

  bool get estCedee => dateCession != null;
}
