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
    return Immobilisation(
      id: map['id'],
      libelle: map['libelle'] ?? map['designation'] ?? '',
      type: map['type'] ?? map['categorie'] ?? '',
      dateAcquisition: DateTime.parse(map['date_acquisition']),
      valeurAcquisition: (map['valeur_acquisition'] as num).toDouble(),
      dureeAmortissement: map['duree_amortissement'] as int,
      methodeAmortissement: map['methode_amortissement'] ?? 'lineaire',
      tauxAmortissement: map['taux_amortissement'] != null
          ? (map['taux_amortissement'] as num).toDouble()
          : null,
      valeurResiduelle: map['valeur_residuelle'] != null
          ? (map['valeur_residuelle'] as num).toDouble()
          : (map['valeur_nette_comptable'] != null
              ? (map['valeur_nette_comptable'] as num).toDouble()
              : 0),
      compteImmobilisation: map['compte_immobilisation'],
      compteAmortissement: map['compte_amortissement'],
      enService: map['en_service'] == 1 || map['en_service'] == true,
      dateCession: map['date_cession'] != null
          ? DateTime.parse(map['date_cession'])
          : null,
      notes: map['notes'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : (map['date_creation'] != null
              ? DateTime.parse(map['date_creation'])
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
