import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../features/pedigree/domain/entities/dog.dart';

class ContractService {
  static Future<void> generateAndPrintPuppyContract(Dog dog, String buyerName, String buyerAddress, String price) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('PUPPY BILL OF SALE & CONTRACT', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 24),
              pw.Text('Date: ${DateFormat('MMMM d, yyyy').format(DateTime.now())}'),
              pw.SizedBox(height: 12),
              
              pw.Text('1. PUPPY INFORMATION', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text('Registered Name: ${dog.registeredName}'),
              pw.Text('Call Name: ${dog.callName}'),
              pw.Text('Sex: ${dog.sex}'),
              pw.Text('Color/Markings: ${dog.colorMarkings ?? 'N/A'}'),
              pw.Text('Date of Birth: ${dog.dateOfBirth != null ? DateFormat('MMMM d, yyyy').format(dog.dateOfBirth!) : 'Unknown'}'),
              pw.Text('Microchip #: ${dog.microchipNumber ?? 'N/A'}'),
              pw.SizedBox(height: 24),

              pw.Text('2. BUYER INFORMATION', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text('Name: $buyerName'),
              pw.Text('Address: $buyerAddress'),
              pw.SizedBox(height: 24),

              pw.Text('3. TERMS OF SALE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text('Purchase Price: \$$price'),
              pw.Text('The Seller guarantees that the puppy is in good health at the time of sale. The Buyer agrees to provide a safe and loving home.'),
              pw.SizedBox(height: 48),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 200, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text('Seller Signature'),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 200, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text('Buyer Signature'),
                    ]
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Contract_${dog.callName}.pdf',
    );
  }
}
