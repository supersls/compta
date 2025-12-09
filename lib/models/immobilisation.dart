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
      libelle: map['libelle'],
      type: map['type'],
      dateAcquisition: DateTime.parse(map['date_acquisition']),
      valeurAcquisition: map['valeur_acquisition'],
      dureeAmortissement: map['duree_amortissement'],
      methodeAmortissement: map['methode_amortissement'],
      tauxAmortissement: map['taux_amortissement'],
      valeurResiduelle: map['valeur_residuelle'] ?? 0,
      compteImmobilisation: map['compte_immobilisation'],
      compteAmortissement: map['compte_amortissement'],
      enService: map['en_service'] == 1,
      dateCession: map['date_cession'] != null
          ? DateTime.parse(map['date_cession'])
          : null,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  double get tauxAmortissementCalcule {
    if (tauxAmortissement != null) return tauxAmortissement!;
    return 100 / dureeAmortissement;
  }
}
