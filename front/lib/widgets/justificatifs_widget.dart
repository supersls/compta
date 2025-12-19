import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/justificatif_service.dart';

/// Widget pour gérer l'upload et l'affichage des justificatifs
class JustificatifsWidget extends StatefulWidget {
  final String typeDocument;
  final int? factureId;
  final int? ecritureId;
  final int? clientId;
  final bool readOnly;
  final DateTime? dateDocument;

  const JustificatifsWidget({
    super.key,
    required this.typeDocument,
    this.factureId,
    this.ecritureId,
    this.clientId,
    this.readOnly = false,
    this.dateDocument,
  });

  @override
  State<JustificatifsWidget> createState() => JustificatifsWidgetState();
}

class JustificatifsWidgetState extends State<JustificatifsWidget> {
  final JustificatifService _service = JustificatifService();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<Map<String, dynamic>> _justificatifs = [];
  List<dynamic> _pendingUploads = []; // PlatformFile pour web, File pour mobile
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.factureId != null || widget.ecritureId != null || widget.clientId != null) {
      _loadJustificatifs();
    }
  }

  Future<void> _loadJustificatifs() async {
    if (widget.readOnly) {
      setState(() => _isLoading = true);
      try {
        final justificatifs = await _service.getJustificatifs(
          typeDocument: widget.typeDocument,
          factureId: widget.factureId,
          clientId: widget.clientId,
        );
        setState(() {
          _justificatifs = justificatifs;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'xlsx', 'xls', 'doc', 'docx'],
        withData: kIsWeb, // Sur web, charger les bytes
      );

      if (result != null) {
        setState(() {
          if (kIsWeb) {
            // Sur web, utiliser PlatformFile directement
            _pendingUploads.add(result.files.single);
          } else {
            // Sur mobile/desktop, convertir en File
            File file = File(result.files.single.path!);
            _pendingUploads.add(file);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection: $e')),
        );
      }
    }
  }

  Future<void> _pickFromCamera() async {
    if (kIsWeb) {
      // La caméra n'est pas supportée sur web, utiliser file picker
      _pickFile();
      return;
    }
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        File file = File(image.path);
        setState(() {
          _pendingUploads.add(file);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la prise de photo: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (kIsWeb) {
      // Sur web, utiliser file picker à la place
      _pickFile();
      return;
    }
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        File file = File(image.path);
        setState(() {
          _pendingUploads.add(file);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection: $e')),
        );
      }
    }
  }

  void _removePendingFile(int index) {
    setState(() {
      _pendingUploads.removeAt(index);
    });
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie de photos'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Fichier (PDF, Excel, Word)'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// À appeler depuis le formulaire parent lors de la sauvegarde
  Future<List<int>> uploadPendingFiles({
    int? factureId,
    int? ecritureId,
    int? clientId,
  }) async {
    final uploadedIds = <int>[];

    for (final file in _pendingUploads) {
      try {
        String fileName;
        if (kIsWeb) {
          // Sur web, file est PlatformFile
          fileName = file.name;
        } else {
          // Sur mobile, file est File
          fileName = file.path.split('/').last;
        }
        
        final result = await _service.uploadJustificatif(
          file,
          description: 'Justificatif ${widget.typeDocument}',
          typeDocument: widget.typeDocument,
          dateDocument: widget.dateDocument ?? DateTime.now(),
          factureId: factureId ?? widget.factureId,
          ecritureId: ecritureId ?? widget.ecritureId,
          clientId: clientId ?? widget.clientId,
          fileName: fileName,
        );
        
        if (result['success'] == true && result['justificatif'] != null) {
          uploadedIds.add(result['justificatif']['id']);
        }
      } catch (e) {
        print('Erreur upload fichier: $e');
        // Continue avec les autres fichiers
      }
    }

    return uploadedIds;
  }

  String _getFileName(dynamic file) {
    if (kIsWeb) {
      // Sur web, file est PlatformFile
      return file.name;
    } else {
      // Sur mobile, file est File
      return file.path.split('/').last;
    }
  }

  int _getFileSize(dynamic file) {
    if (kIsWeb) {
      // Sur web, file est PlatformFile avec bytes
      return file.size;
    } else {
      // Sur mobile, file est File
      return file.lengthSync();
    }
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Justificatifs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!widget.readOnly)
                  ElevatedButton.icon(
                    onPressed: _showUploadOptions,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Liste des fichiers en attente d'upload
            if (_pendingUploads.isNotEmpty) ...[
              const Text(
                'En attente d\'upload:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_pendingUploads.length, (index) {
                final file = _pendingUploads[index];
                final fileName = _getFileName(file);
                final fileSize = _getFileSize(file);
                
                return ListTile(
                  leading: Icon(_getFileIcon(fileName)),
                  title: Text(fileName),
                  subtitle: Text('${(fileSize / 1024).toStringAsFixed(1)} KB'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _removePendingFile(index),
                  ),
                );
              }),
              const Divider(),
            ],

            // Liste des justificatifs déjà uploadés
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_justificatifs.isEmpty && _pendingUploads.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Aucun justificatif',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else if (_justificatifs.isNotEmpty) ...[
              const Text(
                'Justificatifs uploadés:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_justificatifs.length, (index) {
                final justif = _justificatifs[index];
                
                return ListTile(
                  leading: Icon(_getFileIcon(justif['nom_original'] ?? '')),
                  title: Text(justif['nom_original'] ?? 'Sans nom'),
                  subtitle: Text(justif['description'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          // Ouvrir dans le navigateur
                          // TODO: Implémenter la visualisation
                        },
                      ),
                      if (!widget.readOnly)
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirmer'),
                                content: const Text('Supprimer ce justificatif ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              try {
                                await _service.deleteJustificatif(justif['id']);
                                _loadJustificatifs();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erreur: $e')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
