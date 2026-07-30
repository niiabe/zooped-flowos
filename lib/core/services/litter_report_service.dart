import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import '../../core/database/app_database.dart' show LitterHealthRecord;
import '../../features/pedigree/domain/entities/dog.dart';
import '../../features/pedigree/domain/entities/litter.dart';
import '../../features/settings/domain/entities/kennel_profile.dart';

class LitterReportPayload {
  final KennelProfile kennelProfile;
  final Litter litter;
  final Dog? sire;
  final Dog? dam;
  final List<Dog> puppies;
  final List<LitterHealthRecord> healthRecords;

  LitterReportPayload({
    required this.kennelProfile,
    required this.litter,
    this.sire,
    this.dam,
    required this.puppies,
    required this.healthRecords,
  });
}

class LitterReportService {
  static Future<Uint8List> generateReport(LitterReportPayload payload) async {
    return await compute(_buildPdfIsolate, payload);
  }

  static Future<Uint8List> _buildPdfIsolate(LitterReportPayload payload) async {
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
                    'Litter Health Report',
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
          return [
            // Litter Overview Section
            pw.Text('Litter Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: baseColor)),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Sire: ${payload.sire?.registeredName ?? 'Unknown'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Dam: ${payload.dam?.registeredName ?? 'Unknown'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Whelped: ${DateFormat('MMMM d, yyyy').format(payload.litter.whelpingDate)}'),
                      pw.Text('Total Puppies: ${payload.puppies.length}'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Health Records Table
            pw.Text('Litter Health History', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: baseColor)),
            pw.SizedBox(height: 8),
            if (payload.healthRecords.isEmpty)
              pw.Text('No health records logged for this litter.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey))
            else
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: baseColor),
                rowDecoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellPadding: const pw.EdgeInsets.all(8),
                headers: ['Date', 'Type', 'Notes'],
                data: payload.healthRecords.map((r) {
                  return [
                    DateFormat('MMM d, yyyy').format(r.date),
                    r.recordType,
                    r.notes ?? '',
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 24),

            // Puppy Roster Table
            pw.Text('Puppy Roster', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: baseColor)),
            pw.SizedBox(height: 8),
            if (payload.puppies.isEmpty)
              pw.Text('No puppies recorded for this litter yet.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey))
            else
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: secondaryColor),
                rowDecoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellPadding: const pw.EdgeInsets.all(8),
                headers: ['Call Name', 'Sex', 'Color/Markings', 'Microchip'],
                data: payload.puppies.map((p) {
                  return [
                    p.callName,
                    p.sex,
                    p.colorMarkings ?? '',
                    p.microchipNumber ?? '',
                  ];
                }).toList(),
              ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  static Future<void> printPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Litter_Health_Report.pdf',
    );
  }

  static Future<void> sharePdf(Uint8List pdfBytes, String litterIdStr) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, 'Litter_Report_$litterIdStr.pdf'));
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Litter Health Report',
    );
  }
}
