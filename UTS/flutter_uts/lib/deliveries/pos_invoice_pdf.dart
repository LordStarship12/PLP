import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class POSInvoicePDFPreview extends StatelessWidget {
  final Map<String, dynamic> invoiceData;
  final List<DocumentSnapshot> detailDocs;

  POSInvoicePDFPreview({
    Key? key,
    required this.invoiceData,
    required this.detailDocs,
  }) : super(key: key);

  final _fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFmt = DateFormat("d MMMM y HH:mm", 'id_ID');

  Future<String> _getName(DocumentReference? ref) async {
    if (ref == null) return '-';
    final snap = await ref.get();
    final data = snap.data() as Map<String, dynamic>?;
    return data?['name'] ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Faktur')),
      body: PdfPreview(
        build: (format) async {
          final pdf = pw.Document();

          final details = await Future.wait(detailDocs.map((d) async {
            final m = d.data() as Map<String, dynamic>;
            final prod = await (m['product_ref'] as DocumentReference).get();
            return {
              'name': prod['name'],
              'qty': m['qty'],
              'price': m['price'],
              'subtotal': m['subtotal'],
            };
          }));

          // Fetch header names
          final customerName = await _getName(invoiceData['customer_store_ref']);
          final warehouseName = await _getName(invoiceData['warehouse_ref']);
          final salesmanName = await _getName(invoiceData['salesman_ref']);

          pdf.addPage(pw.Page(
            margin: const pw.EdgeInsets.all(24),
            build: (ctx) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Faktur Penjualan', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 12),

                  // Header info
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('No. Faktur: ${invoiceData['no_faktur']}'),
                          pw.Text('Tanggal: ${_dateFmt.format(DateTime.parse(invoiceData['post_date']))}'),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Customer: $customerName'),
                          pw.Text('Gudang: $warehouseName'),
                          pw.Text('Salesman: $salesmanName'),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),

                  // Item Table
                  pw.TableHelper.fromTextArray(
                    border: null,
                    cellStyle: const pw.TextStyle(fontSize: 10),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
                    cellAlignment: pw.Alignment.centerLeft,
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(2),
                    },
                    headers: ['Produk', 'Qty', 'Harga', 'Subtotal'],
                    data: details.map((e) => [
                      e['name'],
                      '${e['qty']} pcs',
                      _fmt.format(e['price']),
                      _fmt.format(e['subtotal']),
                    ]).toList(),
                  ),
                  pw.Divider(),

                  // Totals
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.only(top: 8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Total Items: ${invoiceData['item_total']}'),
                          pw.Text('Total Bayar: ${_fmt.format(invoiceData['grandtotal'])}',
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                  if ((invoiceData['description'] ?? '').toString().isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 24),
                      child: pw.Text('Catatan: ${invoiceData['description']}', style: const pw.TextStyle(fontSize: 10)),
                    ),
                ],
              );
            },
          ));

          return pdf.save();
        },
      ),
    );
  }
}
