class Client {
  final int? id;
  final String nom;
  final String? siret;
  final String? adresse;
  final String? codePostal;
  final String? ville;
  final String? pays;
  final String? email;
  final String? telephone;
  final String? contactPrincipal;
  final String? tvaIntracommunautaire;
  final String? conditionsPaiement;
  final String? notes;
  final bool actif;
  final DateTime createdAt;
  final DateTime updatedAt;

  Client({
    this.id,
    required this.nom,
    this.siret,
    this.adresse,
    this.codePostal,
    this.ville,
    this.pays,
    this.email,
    this.telephone,
    this.contactPrincipal,
    this.tvaIntracommunautaire,
    this.conditionsPaiement,
    this.notes,
    this.actif = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'siret': siret,
      'adresse': adresse,
      'code_postal': codePostal,
      'ville': ville,
      'pays': pays ?? 'France',
      'email': email,
      'telephone': telephone,
      'contact_principal': contactPrincipal,
      'tva_intracommunautaire': tvaIntracommunautaire,
      'conditions_paiement': conditionsPaiement,
      'notes': notes,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      nom: map['nom'] ?? '',
      siret: map['siret'],
      adresse: map['adresse'],
      codePostal: map['code_postal'],
      ville: map['ville'],
      pays: map['pays'],
      email: map['email'],
      telephone: map['telephone'],
      contactPrincipal: map['contact_principal'],
      tvaIntracommunautaire: map['tva_intracommunautaire'],
      conditionsPaiement: map['conditions_paiement'],
      notes: map['notes'],
      actif: map['actif'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
    );
  }

  Client copyWith({
    int? id,
    String? nom,
    String? siret,
    String? adresse,
    String? codePostal,
    String? ville,
    String? pays,
    String? email,
    String? telephone,
    String? contactPrincipal,
    String? tvaIntracommunautaire,
    String? conditionsPaiement,
    String? notes,
    bool? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      siret: siret ?? this.siret,
      adresse: adresse ?? this.adresse,
      codePostal: codePostal ?? this.codePostal,
      ville: ville ?? this.ville,
      pays: pays ?? this.pays,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      contactPrincipal: contactPrincipal ?? this.contactPrincipal,
      tvaIntracommunautaire: tvaIntracommunautaire ?? this.tvaIntracommunautaire,
      conditionsPaiement: conditionsPaiement ?? this.conditionsPaiement,
      notes: notes ?? this.notes,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get adresseComplete {
    List<String> parts = [];
    if (adresse != null && adresse!.isNotEmpty) parts.add(adresse!);
    if (codePostal != null && codePostal!.isNotEmpty) {
      String cityLine = codePostal!;
      if (ville != null && ville!.isNotEmpty) cityLine += ' $ville';
      parts.add(cityLine);
    } else if (ville != null && ville!.isNotEmpty) {
      parts.add(ville!);
    }
    if (pays != null && pays!.isNotEmpty && pays != 'France') {
      parts.add(pays!);
    }
    return parts.join('\n');
  }

  @override
  String toString() {
    return 'Client{id: $id, nom: $nom, email: $email, actif: $actif}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Client &&
        other.id == id &&
        other.nom == nom &&
        other.siret == siret &&
        other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nom.hashCode ^
        siret.hashCode ^
        email.hashCode;
  }
}
