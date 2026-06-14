import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../features/pedigree/domain/entities/dog.dart';
import '../../features/settings/domain/entities/kennel_profile.dart';

class CertificateService {
  static Future<pw.Document> generateCertificate({
    required Dog dog,
    required KennelProfile kennelProfile,
    File? logoFile,
  }) async {
    final pdf = pw.Document();
    final logoBytes = logoFile != null ? await logoFile.readAsBytes() : null;
    final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          if (logoImage != null)
            pw.Center(
              child: pw.Image(logoImage, height: 80),
            ),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'PEDIGREE CERTIFICATE',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#3CB91A'),
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              kennelProfile.kennelName,
              style: pw.TextStyle(
                fontSize: 16,
                color: PdfColor.fromHex('#3D3D3D'),
              ),
            ),
          ),
          if (kennelProfile.breederName != null)
            pw.Center(
              child: pw.Text(
                'Breeder: ${kennelProfile.breederName}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          pw.Divider(thickness: 2, color: PdfColor.fromHex('#3CB91A')),
          pw.SizedBox(height: 20),

          // Dog Information
          pw.Text(
            'DOG INFORMATION',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#3D3D3D'),
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('Registered Name', dog.registeredName),
          _buildInfoRow('Call Name', dog.callName),
          _buildInfoRow('Sex', dog.sex),
          if (dog.microchipNumber != null)
            _buildInfoRow('Microchip', dog.microchipNumber!),
          if (dog.dateOfBirth != null)
            _buildInfoRow('Date of Birth', dog.dateOfBirth.toString().split(' ')[0]),
          if (dog.colorMarkings != null)
            _buildInfoRow('Color / Markings', dog.colorMarkings!),
          if (dog.registerType != null)
            _buildInfoRow('Register Type', dog.registerType!),
          if (dog.appraisalScore != null)
            _buildInfoRow('Appraisal Score', dog.appraisalScore.toString()),
          if (dog.inbreedingCoefficient != null)
            _buildInfoRow('COI', dog.inbreedingCoefficient.toString()),
          if (dog.dnaProfileNumber != null)
            _buildInfoRow('DNA Profile', dog.dnaProfileNumber!),
          pw.SizedBox(height: 20),

          // Sire (Father)
          pw.Text(
            'SIRE (FATHER)',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#3D3D3D'),
            ),
          ),
          pw.SizedBox(height: 10),
          if (dog.sire != null) ...[
            _buildInfoRow('Name', dog.sire!.registeredName),
            _buildInfoRow('Call Name', dog.sire!.callName),
            if (dog.sire!.microchipNumber != null)
              _buildInfoRow('Microchip', dog.sire!.microchipNumber!),
            if (dog.sire!.sire != null)
              _buildInfoRow('Sire', dog.sire!.sire!.registeredName),
            if (dog.sire!.dam != null)
              _buildInfoRow('Dam', dog.sire!.dam!.registeredName),
          ] else
            pw.Text('Not registered', style: const pw.TextStyle(color: PdfColors.grey)),
          pw.SizedBox(height: 20),

          // Dam (Mother)
          pw.Text(
            'DAM (MOTHER)',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#3D3D3D'),
            ),
          ),
          pw.SizedBox(height: 10),
          if (dog.dam != null) ...[
            _buildInfoRow('Name', dog.dam!.registeredName),
            _buildInfoRow('Call Name', dog.dam!.callName),
            if (dog.dam!.microchipNumber != null)
              _buildInfoRow('Microchip', dog.dam!.microchipNumber!),
            if (dog.dam!.sire != null)
              _buildInfoRow('Sire', dog.dam!.sire!.registeredName),
            if (dog.dam!.dam != null)
              _buildInfoRow('Dam', dog.dam!.dam!.registeredName),
          ] else
            pw.Text('Not registered', style: const pw.TextStyle(color: PdfColors.grey)),
          pw.SizedBox(height: 30),

          // Grandparents Section (3 Gen)
          pw.Text(
            'GRANDPARENTS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#3D3D3D'),
            ),
          ),
          pw.SizedBox(height: 10),
          _buildGrandparentRow('Sire\'s Sire', dog.sire?.sire),
          _buildGrandparentRow('Sire\'s Dam', dog.sire?.dam),
          _buildGrandparentRow('Dam\'s Sire', dog.dam?.sire),
          _buildGrandparentRow('Dam\'s Dam', dog.dam?.dam),
          pw.SizedBox(height: 30),

          // Footer
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated: ${DateTime.now().toString().split('.')[0]}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'ZooPed - Pedigree Management',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          if (kennelProfile.contactInfo != null) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              'Contact: ${kennelProfile.contactInfo}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildGrandparentRow(String label, Dog? dog) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              dog != null ? '${dog.registeredName} (${dog.callName})' : 'Not registered',
              style: pw.TextStyle(
                color: dog != null ? PdfColors.black : PdfColors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<File> savePdfToTemp(pw.Document pdf, String fileName) async {
    final output = await getTemporaryDirectory();
    final file = File(p.join(output.path, fileName));
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> printPdf(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'ZooPed Pedigree Certificate',
    );
  }

  static Future<void> sharePdf(File pdfFile, String dogName) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      text: 'Pedigree Certificate for $dogName',
      subject: 'ZooPed - Pedigree Certificate',
    );
  }
}
