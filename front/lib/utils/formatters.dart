import 'package:intl/intl.dart';
import 'constants.dart';

class AppFormatters {
  /// Formatte un montant en euros
  static String formatMontant(double montant) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );
    return formatter.format(montant);
  }

  /// Formatte un montant sans symbole
  static String formatMontantSansSymbole(double montant) {
    final formatter = NumberFormat.decimalPattern('fr_FR');
    return formatter.format(montant);
  }

  /// Formatte une date au format français
  static String formatDate(DateTime date) {
    final formatter = DateFormat(AppConstants.FORMAT_DATE_FR, 'fr_FR');
    return formatter.format(date);
  }

  /// Formatte une date et heure au format français
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat(AppConstants.FORMAT_DATETIME_FR, 'fr_FR');
    return formatter.format(dateTime);
  }

  /// Parse une date au format français
  static DateTime? parseDate(String dateString) {
    try {
      final formatter = DateFormat(AppConstants.FORMAT_DATE_FR, 'fr_FR');
      return formatter.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Formatte un pourcentage
  static String formatPourcentage(double valeur) {
    return '${valeur.toStringAsFixed(1)}%';
  }

  /// Formatte un numéro de téléphone français
  static String formatTelephone(String numero) {
    if (numero.length == 10) {
      return '${numero.substring(0, 2)} ${numero.substring(2, 4)} ${numero.substring(4, 6)} ${numero.substring(6, 8)} ${numero.substring(8, 10)}';
    }
    return numero;
  }

  /// Formatte un SIRET
  static String formatSIRET(String siret) {
    if (siret.length == 14) {
      return '${siret.substring(0, 3)} ${siret.substring(3, 6)} ${siret.substring(6, 9)} ${siret.substring(9, 14)}';
    }
    return siret;
  }

  /// Formatte un IBAN
  static String formatIBAN(String iban) {
    String formatted = '';
    for (int i = 0; i < iban.length; i += 4) {
      if (i + 4 < iban.length) {
        formatted += '${iban.substring(i, i + 4)} ';
      } else {
        formatted += iban.substring(i);
      }
    }
    return formatted.trim();
  }

  /// Génère un numéro de facture
  static String genererNumeroFacture(String type, int annee, int numero) {
    final prefix = type == AppConstants.TYPE_VENTE ? 'FAC' : 'ACH';
    return '$prefix-$annee-${numero.toString().padLeft(4, '0')}';
  }

  /// Génère un numéro de pièce comptable
  static String genererNumeroPiece(String journal, DateTime date, int numero) {
    final year = date.year.toString().substring(2);
    final month = date.month.toString().padLeft(2, '0');
    final journalCode = journal.substring(0, 2).toUpperCase();
    return '$journalCode$year$month${numero.toString().padLeft(4, '0')}';
  }

  /// Arrondit un montant à 2 décimales
  static double arrondir(double montant) {
    return (montant * 100).round() / 100;
  }

  /// Formatte une période (mois/année)
  static String formatPeriode(DateTime debut, DateTime fin) {
    if (debut.year == fin.year && debut.month == fin.month) {
      return DateFormat('MMMM yyyy', 'fr_FR').format(debut);
    }
    return '${formatDate(debut)} - ${formatDate(fin)}';
  }

  /// Formatte un trimestre
  static String formatTrimestre(int trimestre, int annee) {
    return 'T$trimestre $annee';
  }

  /// Retourne le nom du mois en français
  static String getNomMois(int mois) {
    const mois_fr = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return mois >= 1 && mois <= 12 ? mois_fr[mois - 1] : '';
  }
}

// Alias pour compatibilité
class Formatters {
  static String currency(double montant) {
    return AppFormatters.formatMontant(montant);
  }

  static String date(DateTime date) {
    return AppFormatters.formatDate(date);
  }

  static String dateTime(DateTime dateTime) {
    return AppFormatters.formatDateTime(dateTime);
  }

  static String percentage(double valeur) {
    return AppFormatters.formatPourcentage(valeur);
  }
}
