// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Helper pour ouvrir des URLs dans le navigateur (Flutter Web)
class UrlHelper {
  /// Ouvre une URL dans un nouvel onglet
  static void openInNewTab(String url) {
    html.window.open(url, '_blank');
  }

  /// Déclenche le téléchargement d'un fichier
  static void downloadFile(String url, String filename) {
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
  }
}
