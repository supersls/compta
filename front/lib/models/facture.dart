class Facture {
  final int? id;
  final String numero;
  final String type; // 'vente' ou 'achat'
  final DateTime dateEmission;
  final DateTime? dateEcheance;
  final String clientFournisseur;
  final String? siretClient;
  final double montantHT;
  final double montantTVA;
  final double montantTTC;
  final String statut; // 'en_attente', 'payee', 'partiellement_payee', 'en_retard'
  final double montantPaye;
  final String? categorie;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Facture({
    this.id,
    required this.numero,
    required this.type,
    required this.dateEmission,
    this.dateEcheance,
    required this.clientFournisseur,
    this.siretClient,
    required this.montantHT,
    required this.montantTVA,
    required this.montantTTC,
    this.statut = 'en_attente',
    this.montantPaye = 0,
    this.categorie,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'type': type,
      'date_emission': dateEmission.toIso8601String(),
      'date_echeance': dateEcheance?.toIso8601String(),
      'client_fournisseur': clientFournisseur,
      'siret_client': siretClient,
      'montant_ht': montantHT,
      'montant_tva': montantTVA,
      'montant_ttc': montantTTC,
      'statut': statut,
      'montant_paye': montantPaye,
      'categorie': categorie,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Facture.fromMap(Map<String, dynamic> map) {
    // Helper function to convert to double
    double _toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    // Helper function to convert to int
    int? _toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    return Facture(
      id: _toInt(map['id']),
      numero: map['numero'] ?? '',
      type: map['type'] ?? 'vente',
      dateEmission: map['date_emission'] is String 
          ? DateTime.parse(map['date_emission'])
          : (map['date_emission'] as DateTime?)?? DateTime.now(),
      dateEcheance: map['date_echeance'] != null 
          ? (map['date_echeance'] is String 
              ? DateTime.parse(map['date_echeance'])
              : map['date_echeance'] as DateTime)
          : null,
      clientFournisseur: map['client_fournisseur'] ?? '',
      siretClient: map['siret_client'],
      montantHT: _toDouble(map['montant_ht']),
      montantTVA: _toDouble(map['montant_tva']),
      montantTTC: _toDouble(map['montant_ttc']),
      statut: map['statut'] ?? 'en_attente',
      montantPaye: _toDouble(map['montant_paye']),
      categorie: map['categorie'],
      notes: map['notes'],
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'])
          : (map['created_at'] as DateTime?) ?? DateTime.now(),
      updatedAt: map['updated_at'] is String
          ? DateTime.parse(map['updated_at'])
          : (map['updated_at'] as DateTime?) ?? DateTime.now(),
    );
  }

  Facture copyWith({
    int? id,
    String? numero,
    String? type,
    DateTime? dateEmission,
    DateTime? dateEcheance,
    String? clientFournisseur,
    String? siretClient,
    double? montantHT,
    double? montantTVA,
    double? montantTTC,
    String? statut,
    double? montantPaye,
    String? categorie,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Facture(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      type: type ?? this.type,
      dateEmission: dateEmission ?? this.dateEmission,
      dateEcheance: dateEcheance ?? this.dateEcheance,
      clientFournisseur: clientFournisseur ?? this.clientFournisseur,
      siretClient: siretClient ?? this.siretClient,
      montantHT: montantHT ?? this.montantHT,
      montantTVA: montantTVA ?? this.montantTVA,
      montantTTC: montantTTC ?? this.montantTTC,
      statut: statut ?? this.statut,
      montantPaye: montantPaye ?? this.montantPaye,
      categorie: categorie ?? this.categorie,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get estEnRetard {
    if (dateEcheance == null || statut == 'payee') return false;
    return DateTime.now().isAfter(dateEcheance!);
  }

  double get resteAPayer => montantTTC - montantPaye;
}
