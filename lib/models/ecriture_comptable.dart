class EcritureComptable {
  final int? id;
  final String numeroPiece;
  final DateTime dateEcriture;
  final String journal; // ventes, achats, banque, od
  final String compte;
  final String libelle;
  final double debit;
  final double credit;
  final String? referenceExterne;
  final String? typeReference;
  final String? lettrage;
  final bool validee;
  final int? rectificationDe;
  final String? createdBy;
  final DateTime createdAt;

  EcritureComptable({
    this.id,
    required this.numeroPiece,
    required this.dateEcriture,
    required this.journal,
    required this.compte,
    required this.libelle,
    this.debit = 0,
    this.credit = 0,
    this.referenceExterne,
    this.typeReference,
    this.lettrage,
    this.validee = true,
    this.rectificationDe,
    this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero_piece': numeroPiece,
      'date_ecriture': dateEcriture.toIso8601String(),
      'journal': journal,
      'compte': compte,
      'libelle': libelle,
      'debit': debit,
      'credit': credit,
      'reference_externe': referenceExterne,
      'type_reference': typeReference,
      'lettrage': lettrage,
      'validee': validee ? 1 : 0,
      'rectification_de': rectificationDe,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EcritureComptable.fromMap(Map<String, dynamic> map) {
    return EcritureComptable(
      id: map['id'],
      numeroPiece: map['numero_piece'],
      dateEcriture: DateTime.parse(map['date_ecriture']),
      journal: map['journal'],
      compte: map['compte'],
      libelle: map['libelle'],
      debit: map['debit'] ?? 0,
      credit: map['credit'] ?? 0,
      referenceExterne: map['reference_externe'],
      typeReference: map['type_reference'],
      lettrage: map['lettrage'],
      validee: map['validee'] == 1,
      rectificationDe: map['rectification_de'],
      createdBy: map['created_by'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  bool get estEquilibree => (debit - credit).abs() < 0.01;
}
