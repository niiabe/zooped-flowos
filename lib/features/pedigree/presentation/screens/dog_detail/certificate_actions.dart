import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import '../../../../../core/services/certificate_service.dart';
import '../../../domain/entities/dog.dart';
import '../../providers/shared_providers.dart';
import '../../../../settings/presentation/providers/settings_providers.dart';

class CertificateActions extends ConsumerStatefulWidget {
  final Dog dog;
  final bool generatingPdf;
  final ValueChanged<bool> onGeneratingChanged;
  final GlobalKey exportKey;

  const CertificateActions({
    super.key,
    required this.dog,
    required this.generatingPdf,
    required this.onGeneratingChanged,
    required this.exportKey,
  });

  @override
  ConsumerState<CertificateActions> createState() => _CertificateActionsState();
}

class _CertificateActionsState extends ConsumerState<CertificateActions> {
  Future<Map<int, Uint8List>> _preloadDogImages(Dog rootDog) async {
    final Map<int, Uint8List> imageMap = {};
    final List<Dog> allAncestors = [rootDog];

    int i = 0;
    while (i < allAncestors.length) {
      final current = allAncestors[i];
      if (current.sire != null) allAncestors.add(current.sire!);
      if (current.dam != null) allAncestors.add(current.dam!);
      i++;
    }

    await Future.wait(allAncestors.map((dog) async {
      if (dog.photoPath != null && dog.photoPath!.isNotEmpty) {
        try {
          final file = File(dog.photoPath!);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            imageMap[dog.id] = bytes;
          }
        } catch (_) {}
      }
    }));

    return imageMap;
  }

  Future<Uint8List> _generateCertificate(Dog dog) async {
    final profile = await ref.read(kennelProfileProvider.future);
    final logoFile = profile.localLogoPath != null ? File(profile.localLogoPath!) : null;
    final preloadedImages = await _preloadDogImages(dog);

    return CertificateService.generateCertificate(
      dog: dog,
      kennelProfile: profile,
      logoFile: logoFile,
      preloadedImages: preloadedImages,
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final padding = isTablet ? 16.0 : 12.0;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.generatingPdf ? null : _printCertificate,
            icon: widget.generatingPdf
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.print, size: 20),
            label: const Text('Print'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: padding),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
          ),
        ),
        SizedBox(width: padding * 0.5),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.generatingPdf ? null : _sharePdf,
            icon: widget.generatingPdf
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf, size: 20),
            label: const Text('PDF'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: padding),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
          ),
        ),
        SizedBox(width: padding * 0.5),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.generatingPdf ? null : _shareSocial,
            icon: widget.generatingPdf
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.share, size: 20),
            label: const Text('Social'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: padding),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _printCertificate() async {
    widget.onGeneratingChanged(true);
    try {
      final pdfBytes = await _generateCertificate(widget.dog);
      await CertificateService.printPdf(pdfBytes);
    } on SqliteException catch (e) {
      _showError(e.message.contains('UNIQUE')
          ? 'A record with this name or microchip already exists'
          : 'Error generating certificate: $e');
    } catch (e) {
      _showError('Error generating certificate: $e');
    } finally {
      widget.onGeneratingChanged(false);
    }
  }

  Future<void> _sharePdf() async {
    widget.onGeneratingChanged(true);
    try {
      final pdfBytes = await _generateCertificate(widget.dog);
      await CertificateService.sharePdf(pdfBytes, widget.dog.registeredName);
    } on SqliteException catch (e) {
      _showError(e.message.contains('UNIQUE')
          ? 'A record with this name or microchip already exists'
          : 'Error generating certificate: $e');
    } catch (e) {
      _showError('Error generating certificate: $e');
    } finally {
      widget.onGeneratingChanged(false);
    }
  }

  Future<void> _shareSocial() async {
    widget.onGeneratingChanged(true);
    try {
      final pdfBytes = await _generateCertificate(widget.dog);

      await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 300)) {
        final pngBytes = await page.toPng();
        final tempDir = await getTemporaryDirectory();
        final file = File(p.join(tempDir.path, 'social_pedigree_${widget.dog.id}.png'));
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Check out ${widget.dog.callName}\'s Pedigree! #ZooPed',
        );
        break;
      }
    } catch (e) {
      _showError('Error generating image: $e');
    } finally {
      widget.onGeneratingChanged(false);
    }
  }
}
