class Entreprise {
  final int id;
  final String nom;
  final String? siret;
  final String? adresse;
  final String? codePostal;
  final String? ville;
  final String? email;
  final String? telephone;
  final String? regimeTva;
  final DateTime? dateClotureExercice;
  final DateTime? createdAt;

  Entreprise({
    required this.id,
    required this.nom,
    this.siret,
    this.adresse,
    this.codePostal,
    this.ville,
    this.email,
    this.telephone,
    this.regimeTva,
    this.dateClotureExercice,
    this.createdAt,
  });

  factory Entreprise.fromJson(Map<String, dynamic> json) {
    return Entreprise(
      id: json['id'] as int,
      nom: json['nom'] as String,
      siret: json['siret'] as String?,
      adresse: json['adresse'] as String?,
      codePostal: json['code_postal'] as String?,
      ville: json['ville'] as String?,
      email: json['email'] as String?,
      telephone: json['telephone'] as String?,
      regimeTva: json['regime_tva'] as String?,
      dateClotureExercice: json['date_cloture_exercice'] != null
          ? DateTime.parse(json['date_cloture_exercice'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'siret': siret,
      'adresse': adresse,
      'code_postal': codePostal,
      'ville': ville,
      'email': email,
      'telephone': telephone,
      'regime_tva': regimeTva,
      'date_cloture_exercice': dateClotureExercice?.toIso8601String(),
    };
  }
}
