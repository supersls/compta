class Amortissement {
  final int? id;
  final int immobilisationId;
  final int exercice;
  final int annee;
  final double montantAmortissement;
  final double cumulAmortissements;
  final double valeurNetteComptable;
  final DateTime createdAt;

  Amortissement({
    this.id,
    required this.immobilisationId,
    required this.exercice,
    required this.annee,
    required this.montantAmortissement,
    required this.cumulAmortissements,
    required this.valeurNetteComptable,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'immobilisation_id': immobilisationId,
      'exercice': exercice,
      'annee': annee,
      'montant_amortissement': montantAmortissement,
      'cumul_amortissements': cumulAmortissements,
      'valeur_nette_comptable': valeurNetteComptable,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Amortissement.fromMap(Map<String, dynamic> map) {
    return Amortissement(
      id: map['id'],
      immobilisationId: map['immobilisation_id'],
      exercice: map['exercice'],
      annee: map['annee'],
      montantAmortissement: map['montant_amortissement'],
      cumulAmortissements: map['cumul_amortissements'],
      valeurNetteComptable: map['valeur_nette_comptable'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
