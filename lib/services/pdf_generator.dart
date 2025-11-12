import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/order.dart';

class PdfGenerator {
  static Future<void> generateOrderPdf({
    required Order order,
    required List<Map<String, dynamic>> orderItems,
  }) async {
    final pdf = pw.Document();

    final orderData = {
      'numero_commande': order.numeroCommande ?? 'CMD-${DateTime.now().millisecondsSinceEpoch}',
      'date': order.date,
      'mode_paiement': order.modePaiement,
      'status': order.status,
      'total': order.total,
      'adresse_livraison': order.adresseJson,
      'articles': orderItems
          .map((item) => {
                'nom': item['nom'],
                'quantite': item['qty'],
                'prix_unitaire': item['prix'],
                'total_article': item['prix'] * item['qty'],
              })
          .toList(),
    };

    final qrValidationResult = QrValidator.validate(
      data: jsonEncode(orderData),
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
    );

    final qrCode = qrValidationResult.qrCode;
    final painter = QrPainter.withQr(
      qr: qrCode!,
      color: const Color(0xFF000000),
      gapless: true,
    );

    final picData = await painter.toImageData(200);
    final pdfImage = pw.MemoryImage(picData!.buffer.asUint8List());

    String formattedAddress = 'Non spécifiée';
    if (order.adresseJson != null) {
      try {
        final addressMap = json.decode(order.adresseJson!) as Map<String, dynamic>;
        formattedAddress = '''
${addressMap['nom'] ?? ''}
${addressMap['adresse'] ?? ''}
${addressMap['cp'] ?? ''} ${addressMap['ville'] ?? ''}
''';
      } catch (e) {
        formattedAddress = order.adresseJson!;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'SmartFit',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.Text(
                    'FACTURE',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'N° Commande : ${order.numeroCommande ?? "CMD-${DateTime.now().millisecondsSinceEpoch}"}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Date : ${order.date}'),
                  pw.Text('Mode de paiement : ${order.modePaiement}'),
                  pw.Text('Statut : ${order.status}'),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Adresse de livraison :',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(formattedAddress),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            pw.Table.fromTextArray(
              headers: ['Produit', 'Quantité', 'Prix unitaire', 'Total'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              data: orderItems
                  .map((item) => [
                        item['nom'],
                        item['qty'].toString(),
                        '${item['prix'].toStringAsFixed(2)} €',
                        '${(item['prix'] * item['qty']).toStringAsFixed(2)} €',
                      ])
                  .toList(),
              border: null,
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
            ),

            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey900,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Text(
                    'Total : ${order.total.toStringAsFixed(2)} €',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'QR Code de la commande',
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Image(pdfImage, width: 150, height: 150),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'commande_${order.numeroCommande ?? DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
