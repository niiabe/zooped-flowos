import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import '../../core/database/app_database.dart' show HealthRecord, ShowRecord;
import '../../features/pedigree/domain/entities/dog.dart';
import '../../features/settings/domain/entities/kennel_profile.dart';

class DogProfileReportPayload {
  final KennelProfile kennelProfile;
  final Dog dog;
  final List<HealthRecord> healthRecords;
  final List<ShowRecord> showRecords;

  DogProfileReportPayload({
    required this.kennelProfile,
    required this.dog,
    required this.healthRecords,
    required this.showRecords,
  });
}

class DogProfileReportService {
  static Future<Uint8List> generateReport(DogProfileReportPayload payload) async {
    return await compute(_buildPdfIsolate, payload);
  }

  static Future<Uint8List> _buildPdfIsolate(DogProfileReportPayload payload) async {
    final pdf = pw.Document();
    
    final brandHex = payload.kennelProfile.brandColorHex ?? '#1E88E5';
    final baseColor = PdfColor.fromHex(brandHex);
    final secondaryColor = PdfColor.fromHex('#4A4A4A');
    final lightGrey = PdfColor.fromHex('#F5F5F5');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    payload.kennelProfile.kennelName,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: baseColor,
                    ),
                  ),
                  pw.Text(
                    'Dog Profile Report',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
              if (payload.kennelProfile.email != null)
                pw.Text(payload.kennelProfile.email!, style: pw.TextStyle(color: secondaryColor, fontSize: 10)),
              pw.SizedBox(height: 16),
              pw.Divider(color: baseColor, thickness: 2),
              pw.SizedBox(height: 16),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
            ),
          );
        },
        build: (pw.Context context) {
          final dog = payload.dog;
          final age = dog.dateOfBirth != null ? _calculateAge(dog.dateOfBirth!) : 'Unknown';

          return [
            // Dog Identity Section
            pw.Text('Dog Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: baseColor)),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(dog.registeredName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                          pw.Text('Call Name: ${dog.callName}', style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Sex: ${dog.sex}', style: const pw.TextStyle(fontSize: 12)),
                          pw.Text('Age: $age', style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(),
                  pw.SizedBox(height: 8),
                  _buildDetailRow('Breed', dog.breed ?? 'Unknown'),
                  _buildDetailRow('Color/Markings', dog.colorMarkings ?? 'Unknown'),
                  _buildDetailRow('Microchip', dog.microchipNumber ?? 'None'),
                  _buildDetailRow('Registration', dog.registerType ?? 'Unknown'),
                  if (dog.appraisalScore != null)
                    _buildDetailRow('Appraisal Score', dog.appraisalScore!.toStringAsFixed(1)),
                  if (dog.inbreedingCoefficient != null)
                    _buildDetailRow('COI', dog.inbreedingCoefficient!.toStringAsFixed(3)),
                  if (dog.dnaProfileNumber != null)
                    _buildDetailRow('DNA Profile', dog.dnaProfileNumber!),
                  if (dog.sire != null)
                    _buildDetailRow('Sire', dog.sire!.registeredName),
                  if (dog.dam != null)
                    _buildDetailRow('Dam', dog.dam!.registeredName),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Health Records Table
            pw.Text('Health Records', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: baseColor)),
            pw.SizedBox(height: 8),
            if (payload.healthRecords.isEmpty)
              pw.Text('No health records found.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey))
            else
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: baseColor),
                rowDecoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellPadding: const pw.EdgeInsets.all(8),
                headers: ['Date', 'Type', 'Next Due', 'Notes'],
                data: payload.healthRecords.map((r) {
                  return [
                    DateFormat('MMM d, yyyy').format(r.date),
                    r.recordType,
                    r.nextDueDate != null ? DateFormat('MMM d, yyyy').format(r.nextDueDate!) : '-',
                    r.notes ?? '',
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 24),

            // Show Records Table
            pw.Text('Show & Title History', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: baseColor)),
            pw.SizedBox(height: 8),
            if (payload.showRecords.isEmpty)
              pw.Text('No show records found.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey))
            else
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: secondaryColor),
                rowDecoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellPadding: const pw.EdgeInsets.all(8),
                headers: ['Date', 'Event', 'Judge', 'Placement', 'Title'],
                data: payload.showRecords.map((r) {
                  return [
                    DateFormat('MMM d, yyyy').format(r.date),
                    r.eventName,
                    r.judge ?? '-',
                    r.placement ?? '-',
                    r.titleAwarded ?? '-',
                  ];
                }).toList(),
              ),

            // Notes section
            if (dog.notes != null && dog.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Text('Notes', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: baseColor)),
              pw.SizedBox(height: 8),
              pw.Text(dog.notes!, style: const pw.TextStyle(fontSize: 12)),
            ],
          ];
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Text('$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static String _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    if (months < 0) {
      years--;
      months += 12;
    }
    if (years > 0) {
      return '$years yr${years == 1 ? '' : 's'}${months > 0 ? ', $months mo' : ''}';
    }
    return '$months month${months == 1 ? '' : 's'}';
  }

  static Future<void> printPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Dog_Profile_Report.pdf',
    );
  }

  static Future<void> sharePdf(Uint8List pdfBytes, String dogName) async {
    final tempDir = await getTemporaryDirectory();
    final safeName = dogName.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
    final file = File(p.join(tempDir.path, 'Dog_Profile_$safeName.pdf'));
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Dog Profile Report for $dogName',
    );
  }
}
