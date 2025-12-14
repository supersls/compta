class AppValidators {
  /// Valide un email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email optionnel
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }
    return null;
  }

  /// Valide un numéro de téléphone français
  static String? validateTelephone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Téléphone optionnel
    }
    
    final phoneRegex = RegExp(r'^0[1-9]\d{8}$');
    final cleanValue = value.replaceAll(RegExp(r'[\s.-]'), '');
    
    if (!phoneRegex.hasMatch(cleanValue)) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  /// Valide un SIRET
  static String? validateSIRET(String? value) {
    if (value == null || value.isEmpty) {
      return null; // SIRET optionnel
    }
    
    final cleanValue = value.replaceAll(RegExp(r'\s'), '');
    
    if (cleanValue.length != 14) {
      return 'Le SIRET doit contenir 14 chiffres';
    }
    
    if (!RegExp(r'^\d{14}$').hasMatch(cleanValue)) {
      return 'Le SIRET ne doit contenir que des chiffres';
    }
    
    return null;
  }

  /// Valide un IBAN français
  static String? validateIBAN(String? value) {
    if (value == null || value.isEmpty) {
      return null; // IBAN optionnel
    }
    
    final cleanValue = value.replaceAll(RegExp(r'\s'), '');
    
    if (!cleanValue.startsWith('FR')) {
      return 'L\'IBAN doit commencer par FR';
    }
    
    if (cleanValue.length != 27) {
      return 'L\'IBAN français doit contenir 27 caractères';
    }
    
    return null;
  }

  /// Valide un montant
  static String? validateMontant(String? value, {bool obligatoire = true}) {
    if (value == null || value.isEmpty) {
      return obligatoire ? 'Montant requis' : null;
    }
    
    final cleanValue = value.replaceAll(',', '.');
    final montant = double.tryParse(cleanValue);
    
    if (montant == null) {
      return 'Montant invalide';
    }
    
    if (montant < 0) {
      return 'Le montant ne peut pas être négatif';
    }
    
    return null;
  }

  /// Valide un montant positif
  static String? validateMontantPositif(String? value) {
    final validation = validateMontant(value);
    if (validation != null) return validation;
    
    final cleanValue = value!.replaceAll(',', '.');
    final montant = double.parse(cleanValue);
    
    if (montant <= 0) {
      return 'Le montant doit être supérieur à 0';
    }
    
    return null;
  }

  /// Valide un champ requis
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName requis';
    }
    return null;
  }

  /// Valide une quantité
  static String? validateQuantite(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantité requise';
    }
    
    final cleanValue = value.replaceAll(',', '.');
    final quantite = double.tryParse(cleanValue);
    
    if (quantite == null) {
      return 'Quantité invalide';
    }
    
    if (quantite <= 0) {
      return 'La quantité doit être supérieure à 0';
    }
    
    return null;
  }

  /// Valide une durée d'amortissement
  static String? validateDureeAmortissement(String? value) {
    if (value == null || value.isEmpty) {
      return 'Durée requise';
    }
    
    final duree = int.tryParse(value);
    
    if (duree == null) {
      return 'Durée invalide';
    }
    
    if (duree <= 0 || duree > 50) {
      return 'La durée doit être entre 1 et 50 ans';
    }
    
    return null;
  }

  /// Valide un taux de TVA
  static String? validateTauxTVA(double? taux) {
    if (taux == null) {
      return 'Taux de TVA requis';
    }
    
    if (taux < 0 || taux > 100) {
      return 'Le taux doit être entre 0 et 100%';
    }
    
    return null;
  }

  /// Valide une date
  static String? validateDate(DateTime? date, {bool obligatoire = true}) {
    if (date == null) {
      return obligatoire ? 'Date requise' : null;
    }
    return null;
  }

  /// Valide une date d'échéance (doit être après la date d'émission)
  static String? validateDateEcheance(DateTime? dateEcheance, DateTime? dateEmission) {
    if (dateEcheance == null) {
      return null; // Échéance optionnelle
    }
    
    if (dateEmission != null && dateEcheance.isBefore(dateEmission)) {
      return 'L\'échéance doit être après la date d\'émission';
    }
    
    return null;
  }

  /// Nettoie un montant (remplace virgule par point)
  static double? parseMontant(String? value) {
    if (value == null || value.isEmpty) return null;
    final cleanValue = value.replaceAll(',', '.');
    return double.tryParse(cleanValue);
  }

  /// Nettoie un numéro de téléphone
  static String cleanTelephone(String value) {
    return value.replaceAll(RegExp(r'[\s.-]'), '');
  }

  /// Nettoie un SIRET
  static String cleanSIRET(String value) {
    return value.replaceAll(RegExp(r'\s'), '');
  }

  /// Nettoie un IBAN
  static String cleanIBAN(String value) {
    return value.replaceAll(RegExp(r'\s'), '').toUpperCase();
  }
}

// Alias pour compatibilité
class Validators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est requis';
    }
    return null;
  }

  static String? email(String? value) {
    return AppValidators.validateEmail(value);
  }

  static String? siret(String? value) {
    return AppValidators.validateSIRET(value);
  }

  static String? telephone(String? value) {
    return AppValidators.validateTelephone(value);
  }

  static String? iban(String? value) {
    return AppValidators.validateIBAN(value);
  }

  static String? montant(String? value, {bool obligatoire = true}) {
    return AppValidators.validateMontant(value, obligatoire: obligatoire);
  }
}
