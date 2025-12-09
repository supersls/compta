class CompteBancaire {
  final int? id;
  final String nom;
  final String? banque;
  final String? numeroCompte;
  final String? iban;
  final double soldeInitial;
  final double soldeActuel;
  final DateTime? dateOuverture;
  final bool actif;
  final DateTime createdAt;

  CompteBancaire({
    this.id,
    required this.nom,
    this.banque,
    this.numeroCompte,
    this.iban,
    this.soldeInitial = 0,
    this.soldeActuel = 0,
    this.dateOuverture,
    this.actif = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'banque': banque,
      'numero_compte': numeroCompte,
      'iban': iban,
      'solde_initial': soldeInitial,
      'solde_actuel': soldeActuel,
      'date_ouverture': dateOuverture?.toIso8601String(),
      'actif': actif ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CompteBancaire.fromMap(Map<String, dynamic> map) {
    return CompteBancaire(
      id: map['id'],
      nom: map['nom'],
      banque: map['banque'],
      numeroCompte: map['numero_compte'],
      iban: map['iban'],
      soldeInitial: map['solde_initial'],
      soldeActuel: map['solde_actuel'],
      dateOuverture: map['date_ouverture'] != null
          ? DateTime.parse(map['date_ouverture'])
          : null,
      actif: map['actif'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
