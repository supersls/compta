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
    // Helper to convert to double
    double _toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return EcritureComptable(
      id: map['id'],
      numeroPiece: map['numero_piece'] ?? '',
      dateEcriture: map['date_ecriture'] is String
          ? DateTime.parse(map['date_ecriture'])
          : (map['date_ecriture'] as DateTime?) ?? DateTime.now(),
      journal: map['journal'] ?? '',
      compte: map['compte'] ?? '',
      libelle: map['libelle'] ?? '',
      debit: _toDouble(map['debit']),
      credit: _toDouble(map['credit']),
      referenceExterne: map['reference_externe'],
      typeReference: map['type_reference'],
      lettrage: map['lettrage'],
      validee: map['validee'] == 1 || map['validee'] == true,
      rectificationDe: map['rectification_de'],
      createdBy: map['created_by'],
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'])
          : (map['created_at'] as DateTime?) ?? DateTime.now(),
    );
  }

  bool get estEquilibree => (debit - credit).abs() < 0.01;
  bool get isDebit => debit > 0;
  bool get isCredit => credit > 0;
}
