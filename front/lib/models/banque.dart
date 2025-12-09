class CompteBancaire {
  final int? id;
  final String nom;
  final String banque;
  final String? numeroCompte;
  final String? iban;
  final double soldeInitial;
  final double soldeActuel;
  final bool actif;
  final DateTime? dateCreation;

  CompteBancaire({
    this.id,
    required this.nom,
    required this.banque,
    this.numeroCompte,
    this.iban,
    this.soldeInitial = 0,
    required this.soldeActuel,
    this.actif = true,
    this.dateCreation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'banque': banque,
      'numero_compte': numeroCompte,
      'iban': iban,
      'solde_initial': soldeInitial,
      'solde_actuel': soldeActuel,
      'actif': actif,
      'date_creation': dateCreation?.toIso8601String(),
    };
  }

  factory CompteBancaire.fromMap(Map<String, dynamic> map) {
    return CompteBancaire(
      id: map['id'],
      nom: map['nom'] ?? '',
      banque: map['banque'] ?? '',
      numeroCompte: map['numero_compte'],
      iban: map['iban'],
      soldeInitial: map['solde_initial'] != null
          ? (map['solde_initial'] as num).toDouble()
          : 0,
      soldeActuel: (map['solde_actuel'] as num).toDouble(),
      actif: map['actif'] == true || map['actif'] == 1,
      dateCreation: map['date_creation'] != null
          ? DateTime.parse(map['date_creation'])
          : null,
    );
  }

  CompteBancaire copyWith({
    int? id,
    String? nom,
    String? banque,
    String? numeroCompte,
    String? iban,
    double? soldeInitial,
    double? soldeActuel,
    bool? actif,
    DateTime? dateCreation,
  }) {
    return CompteBancaire(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      banque: banque ?? this.banque,
      numeroCompte: numeroCompte ?? this.numeroCompte,
      iban: iban ?? this.iban,
      soldeInitial: soldeInitial ?? this.soldeInitial,
      soldeActuel: soldeActuel ?? this.soldeActuel,
      actif: actif ?? this.actif,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  String get ibanFormate {
    if (iban == null || iban!.isEmpty) return '';
    return iban!.replaceAllMapped(
      RegExp(r'.{4}'),
      (match) => '${match.group(0)} ',
    ).trim();
  }

  double get variation => soldeActuel - soldeInitial;

  bool get enDeficit => soldeActuel < 0;
}

class TransactionBancaire {
  final int? id;
  final int compteId;
  final DateTime dateTransaction;
  final String type; // 'credit' ou 'debit'
  final double montant;
  final String? categorie;
  final String? description;
  final String? reference;
  final bool rapproche;
  final DateTime? dateRapprochement;
  final DateTime? dateCreation;
  final String? compteNom;

  TransactionBancaire({
    this.id,
    required this.compteId,
    required this.dateTransaction,
    required this.type,
    required this.montant,
    this.categorie,
    this.description,
    this.reference,
    this.rapproche = false,
    this.dateRapprochement,
    this.dateCreation,
    this.compteNom,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'compte_id': compteId,
      'date_transaction': dateTransaction.toIso8601String().split('T')[0],
      'type': type,
      'montant': montant,
      'categorie': categorie,
      'description': description,
      'reference': reference,
      'rapproche': rapproche,
      'date_rapprochement': dateRapprochement?.toIso8601String(),
      'date_creation': dateCreation?.toIso8601String(),
    };
  }

  factory TransactionBancaire.fromMap(Map<String, dynamic> map) {
    return TransactionBancaire(
      id: map['id'],
      compteId: map['compte_id'] as int,
      dateTransaction: DateTime.parse(map['date_transaction']),
      type: map['type'] ?? 'debit',
      montant: (map['montant'] as num).toDouble(),
      categorie: map['categorie'],
      description: map['description'],
      reference: map['reference'],
      rapproche: map['rapproche'] == true || map['rapproche'] == 1,
      dateRapprochement: map['date_rapprochement'] != null
          ? DateTime.parse(map['date_rapprochement'])
          : null,
      dateCreation: map['date_creation'] != null
          ? DateTime.parse(map['date_creation'])
          : null,
      compteNom: map['compte_nom'],
    );
  }

  TransactionBancaire copyWith({
    int? id,
    int? compteId,
    DateTime? dateTransaction,
    String? type,
    double? montant,
    String? categorie,
    String? description,
    String? reference,
    bool? rapproche,
    DateTime? dateRapprochement,
    DateTime? dateCreation,
    String? compteNom,
  }) {
    return TransactionBancaire(
      id: id ?? this.id,
      compteId: compteId ?? this.compteId,
      dateTransaction: dateTransaction ?? this.dateTransaction,
      type: type ?? this.type,
      montant: montant ?? this.montant,
      categorie: categorie ?? this.categorie,
      description: description ?? this.description,
      reference: reference ?? this.reference,
      rapproche: rapproche ?? this.rapproche,
      dateRapprochement: dateRapprochement ?? this.dateRapprochement,
      dateCreation: dateCreation ?? this.dateCreation,
      compteNom: compteNom ?? this.compteNom,
    );
  }

  bool get isCredit => type == 'credit';
  bool get isDebit => type == 'debit';

  String get libelleCategorie {
    if (categorie == null) return 'Non catégorisée';
    switch (categorie) {
      case 'vente':
        return 'Vente';
      case 'achat':
        return 'Achat';
      case 'salaire':
        return 'Salaire';
      case 'charge':
        return 'Charge';
      case 'investissement':
        return 'Investissement';
      case 'remboursement':
        return 'Remboursement';
      case 'taxe':
        return 'Taxe';
      case 'virement':
        return 'Virement';
      case 'autre':
        return 'Autre';
      default:
        return categorie!;
    }
  }
}
