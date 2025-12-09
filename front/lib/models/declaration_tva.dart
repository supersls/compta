class DeclarationTVA {
  final int? id;
  final DateTime periodeDebut;
  final DateTime periodeFin;
  final double tvaCollectee;
  final double tvaDeductible;
  final double tvaADecaisser;
  final String statut; // 'en_cours', 'validee', 'transmise', 'payee'
  final DateTime? dateTransmission;
  final DateTime? datePaiement;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeclarationTVA({
    this.id,
    required this.periodeDebut,
    required this.periodeFin,
    required this.tvaCollectee,
    required this.tvaDeductible,
    required this.tvaADecaisser,
    this.statut = 'en_cours',
    this.dateTransmission,
    this.datePaiement,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'periode_debut': periodeDebut.toIso8601String(),
      'periode_fin': periodeFin.toIso8601String(),
      'tva_collectee': tvaCollectee,
      'tva_deductible': tvaDeductible,
      'tva_a_decaisser': tvaADecaisser,
      'statut': statut,
      'date_transmission': dateTransmission?.toIso8601String(),
      'date_paiement': datePaiement?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DeclarationTVA.fromMap(Map<String, dynamic> map) {
    return DeclarationTVA(
      id: map['id'],
      periodeDebut: DateTime.parse(map['periode_debut']),
      periodeFin: DateTime.parse(map['periode_fin']),
      tvaCollectee: (map['tva_collectee'] as num).toDouble(),
      tvaDeductible: (map['tva_deductible'] as num).toDouble(),
      tvaADecaisser: (map['tva_a_decaisser'] as num).toDouble(),
      statut: map['statut'] ?? 'en_cours',
      dateTransmission: map['date_transmission'] != null
          ? DateTime.parse(map['date_transmission'])
          : null,
      datePaiement: map['date_paiement'] != null
          ? DateTime.parse(map['date_paiement'])
          : null,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  DeclarationTVA copyWith({
    int? id,
    DateTime? periodeDebut,
    DateTime? periodeFin,
    double? tvaCollectee,
    double? tvaDeductible,
    double? tvaADecaisser,
    String? statut,
    DateTime? dateTransmission,
    DateTime? datePaiement,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeclarationTVA(
      id: id ?? this.id,
      periodeDebut: periodeDebut ?? this.periodeDebut,
      periodeFin: periodeFin ?? this.periodeFin,
      tvaCollectee: tvaCollectee ?? this.tvaCollectee,
      tvaDeductible: tvaDeductible ?? this.tvaDeductible,
      tvaADecaisser: tvaADecaisser ?? this.tvaADecaisser,
      statut: statut ?? this.statut,
      dateTransmission: dateTransmission ?? this.dateTransmission,
      datePaiement: datePaiement ?? this.datePaiement,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get estValidee => statut == 'validee' || statut == 'transmise' || statut == 'payee';
  bool get estTransmise => statut == 'transmise' || statut == 'payee';
  bool get estPayee => statut == 'payee';
  
  String get libellePeriode {
    final debut = '${periodeDebut.day.toString().padLeft(2, '0')}/${periodeDebut.month.toString().padLeft(2, '0')}/${periodeDebut.year}';
    final fin = '${periodeFin.day.toString().padLeft(2, '0')}/${periodeFin.month.toString().padLeft(2, '0')}/${periodeFin.year}';
    return '$debut - $fin';
  }
}
