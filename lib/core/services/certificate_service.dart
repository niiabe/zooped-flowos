import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/pedigree/domain/entities/dog.dart';
import '../../features/settings/domain/entities/kennel_profile.dart';

class CertificateService {
  static Future<pw.Document> generateCertificate({
    required Dog dog,
    required KennelProfile kennelProfile,
    File? logoFile,
    Map<int, pw.MemoryImage> preloadedImages = const {},
  }) async {
    final pdf = pw.Document();
    final logoBytes = logoFile != null ? await logoFile.readAsBytes() : null;
    final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;

    final baseColor = PdfColor.fromHex('#2F5E36'); // Elegant dark green
    final secondaryColor = PdfColor.fromHex('#4A4A4A'); // Dark grey
    final lightGrey = PdfColor.fromHex('#E8E8E8');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: baseColor, width: 3),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // LEFT PANEL: Kennel & Dog Info (35% width)
                pw.Expanded(
                  flex: 35,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Kennel Header
                      if (logoImage != null)
                        pw.Container(
                          height: 80,
                          child: pw.Image(logoImage),
                        ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'OFFICIAL PEDIGREE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: baseColor,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        kennelProfile.kennelName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                      if (kennelProfile.breederName != null)
                        pw.Text(
                          'Breeder: ${kennelProfile.breederName}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
                        ),
                      
                      // Contact Info
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: lightGrey,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            if (kennelProfile.phone != null)
                              pw.Text('Phone: ${kennelProfile.phone}', style: const pw.TextStyle(fontSize: 9)),
                            if (kennelProfile.whatsapp != null)
                              pw.Text('WhatsApp: ${kennelProfile.whatsapp}', style: const pw.TextStyle(fontSize: 9)),
                            if (kennelProfile.email != null)
                              pw.Text('Email: ${kennelProfile.email}', style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                      ),
                      
                      pw.Divider(color: baseColor, thickness: 1.5),
                      pw.SizedBox(height: 8),

                      // Primary Dog Info
                      if (preloadedImages.containsKey(dog.id))
                        pw.Container(
                          width: 100,
                          height: 100,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            image: pw.DecorationImage(
                              image: preloadedImages[dog.id]!,
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                        ),
                      pw.SizedBox(height: 12),
                      
                      pw.Text(
                        dog.registeredName,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Text(
                        'Call Name: "${dog.callName}"',
                        style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
                      ),
                      pw.SizedBox(height: 12),

                      _buildDogDetailGrid(dog),
                    ],
                  ),
                ),
                
                // Vertical Divider
                pw.SizedBox(width: 16),
                pw.Container(width: 1, color: lightGrey),
                pw.SizedBox(width: 16),

                // RIGHT PANEL: Pedigree Tree (65% width)
                pw.Expanded(
                  flex: 65,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '3-GENERATION PEDIGREE',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: baseColor,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Expanded(
                        child: _buildTree(dog, preloadedImages, baseColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildDogDetailGrid(Dog dog) {
    return pw.Column(
      children: [
        _buildInfoRow('Sex', dog.sex),
        if (dog.dateOfBirth != null)
          _buildInfoRow('DOB', DateFormat('yyyy-MM-dd').format(dog.dateOfBirth!)),
        if (dog.microchipNumber != null)
          _buildInfoRow('Microchip', dog.microchipNumber!),
        if (dog.colorMarkings != null)
          _buildInfoRow('Color', dog.colorMarkings!),
        if (dog.registerType != null)
          _buildInfoRow('Registry', dog.registerType!),
        if (dog.dnaProfileNumber != null)
          _buildInfoRow('DNA Profile', dog.dnaProfileNumber!),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTree(Dog dog, Map<int, pw.MemoryImage> images, PdfColor color) {
    // A standard 3-gen tree has 3 columns: Parents, Grandparents, Great-Grandparents.
    // The data model goes: sire/dam (gen 1), their sire/dam (gen 2), their sire/dam (gen 3).
    // In horizontal layout:
    // Left col: Sire, Dam
    // Middle col: Grandsire (Paternal), Granddam (Paternal), Grandsire (Maternal), Granddam (Maternal)
    // Right col: Great-grandsires/dams
    
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Parents (Gen 1)
        pw.Expanded(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildTreeNode(dog.sire, 'Sire', images, color),
              _buildTreeNode(dog.dam, 'Dam', images, color),
            ],
          ),
        ),
        _buildConnectorLine(color),
        
        // Grandparents (Gen 2)
        pw.Expanded(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildTreeNode(dog.sire?.sire, 'Grandsire', images, color),
              _buildTreeNode(dog.sire?.dam, 'Granddam', images, color),
              _buildTreeNode(dog.dam?.sire, 'Grandsire', images, color),
              _buildTreeNode(dog.dam?.dam, 'Granddam', images, color),
            ],
          ),
        ),
        _buildConnectorLine(color),

        // Great-Grandparents (Gen 3)
        pw.Expanded(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildTreeNode(dog.sire?.sire?.sire, 'G-Grandsire', images, color, isSmall: true),
              _buildTreeNode(dog.sire?.sire?.dam, 'G-Granddam', images, color, isSmall: true),
              _buildTreeNode(dog.sire?.dam?.sire, 'G-Grandsire', images, color, isSmall: true),
              _buildTreeNode(dog.sire?.dam?.dam, 'G-Granddam', images, color, isSmall: true),
              _buildTreeNode(dog.dam?.sire?.sire, 'G-Grandsire', images, color, isSmall: true),
              _buildTreeNode(dog.dam?.sire?.dam, 'G-Granddam', images, color, isSmall: true),
              _buildTreeNode(dog.dam?.dam?.sire, 'G-Grandsire', images, color, isSmall: true),
              _buildTreeNode(dog.dam?.dam?.dam, 'G-Granddam', images, color, isSmall: true),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildConnectorLine(PdfColor color) {
    return pw.Container(
      width: 12,
      child: pw.Center(
        child: pw.Container(
          width: 1,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _buildTreeNode(Dog? dog, String role, Map<int, pw.MemoryImage> images, PdfColor color, {bool isSmall = false}) {
    final double boxHeight = isSmall ? 35 : 60;
    final double fontSizeName = isSmall ? 8 : 10;
    final double fontSizeRole = isSmall ? 6 : 8;

    if (dog == null) {
      return pw.Container(
        height: boxHeight,
        margin: const pw.EdgeInsets.symmetric(vertical: 2),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          color: PdfColors.grey100,
        ),
        child: pw.Center(
          child: pw.Text(
            'Unknown $role',
            style: pw.TextStyle(fontSize: fontSizeName, color: PdfColors.grey),
          ),
        ),
      );
    }

    final hasImage = images.containsKey(dog.id) && !isSmall;

    return pw.Container(
      height: boxHeight,
      margin: const pw.EdgeInsets.symmetric(vertical: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 0.5),
        color: PdfColors.white,
      ),
      child: pw.Row(
        children: [
          if (hasImage)
            pw.Container(
              width: boxHeight,
              height: boxHeight,
              decoration: pw.BoxDecoration(
                image: pw.DecorationImage(
                  image: images[dog.id]!,
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    role,
                    style: pw.TextStyle(
                      fontSize: fontSizeRole,
                      color: color,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    dog.registeredName,
                    maxLines: 2,
                    style: pw.TextStyle(
                      fontSize: fontSizeName,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (dog.colorMarkings != null && !isSmall)
                    pw.Text(
                      dog.colorMarkings!,
                      maxLines: 1,
                      style: pw.TextStyle(fontSize: fontSizeRole, color: PdfColors.grey700),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> printPdf(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Pedigree_Certificate',
    );
  }

  static Future<void> sharePdf(File file, String dogName) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Pedigree Certificate for $dogName',
      subject: 'Pedigree Certificate',
    );
  }
}
