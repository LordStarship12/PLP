import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class EditDeliveryModal extends StatefulWidget {
  final DocumentReference invoiceRef;
  final Map<String, dynamic> invoiceData;

  const EditDeliveryModal({
    super.key,
    required this.invoiceRef,
    required this.invoiceData,
  });

  @override
  _EditDeliveryPageState createState() => _EditDeliveryPageState();
}

class _EditDeliveryPageState extends State<EditDeliveryModal> {
  final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  List<DocumentSnapshot> stores = [], warehouses = [], products = [], salesmen = [];
  DocumentReference? chosenStore, chosenWarehouse, chosenSalesman;
  List<_Item> items = [];

  String invoiceNo = '';
  DateTime postDate = DateTime.now();
  final descCtrl = TextEditingController();

  int get itemCount => items.fold(0, (sum, i) => sum + i.qty);
  int get totalAmt => items.fold(0, (sum, i) => sum + i.subtotal);

  // Theme colors
  final Color pastelBlue = const Color(0xFFE3F2FD);
  final Color primaryBlue = const Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    invoiceNo = widget.invoiceData['no_faktur'] ?? '';
    descCtrl.text = widget.invoiceData['description'] ?? '';
    postDate = DateTime.tryParse(widget.invoiceData['post_date'] ?? '') ?? DateTime.now();

    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('customer_ref');
    if (storeRefPath == null) return;
    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);

    final s = await FirebaseFirestore.instance.collection('customers').get();
    final w = await FirebaseFirestore.instance
        .collection('warehouses')
        .where('customer_ref', isEqualTo: storeRef)
        .get();
    final p = await FirebaseFirestore.instance
        .collection('products')
        .where('customer_ref', isEqualTo: storeRef)
        .get();
    final sm = await FirebaseFirestore.instance
        .collection('salesmen')
        .where('customer_ref', isEqualTo: storeRef)
        .get();

    final d = await widget.invoiceRef.collection('details').get();

    setState(() {
      stores = s.docs..removeWhere((doc) => doc.reference.path == storeRefPath);
      warehouses = w.docs;
      products = p.docs;
      salesmen = sm.docs;

      chosenStore = (widget.invoiceData['customer_store_ref'] as DocumentReference?);
      chosenWarehouse = (widget.invoiceData['warehouse_ref'] as DocumentReference?);
      chosenSalesman = (widget.invoiceData['salesman_ref'] as DocumentReference?);

      items = d.docs.map((doc) => _Item.fromMap(doc.data(), products)).toList();
    });
  }

  void _addItem() => setState(() => items.add(_Item(products: products)));

  void _removeItem(int idx) => setState(() => items.removeAt(idx));

  Future<int> _getAvailableStock(DocumentReference prodRef) async {
    if (chosenWarehouse == null) return 0;
    final q = await FirebaseFirestore.instance
        .collection('stocks')
        .where('product_ref', isEqualTo: prodRef)
        .where('warehouse_ref', isEqualTo: chosenWarehouse!)
        .limit(1)
        .get();
    return q.docs.isEmpty ? 0 : (q.docs.first['qty'] as int);
  }

  Future<void> _submit() async {
    if (chosenStore == null ||
        chosenWarehouse == null ||
        chosenSalesman == null ||
        items.isEmpty ||
        items.any((i) => i.productRef == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lengkapi semua data terlebih dahulu')));
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final detailsRef = widget.invoiceRef.collection('details');
    final warehouseRef = chosenWarehouse!;
    final batch = firestore.batch();

    // Step 1: Restore stock from old items
    final oldDetails = await detailsRef.get();
    for (var doc in oldDetails.docs) {
      final data = doc.data();
      final productRef = data['product_ref'] as DocumentReference;
      final oldQty = data['qty'] ?? 0;

      final stockQuery = await firestore
          .collection('stocks')
          .where('product_ref', isEqualTo: productRef)
          .where('warehouse_ref', isEqualTo: warehouseRef)
          .limit(1)
          .get();

      if (stockQuery.docs.isNotEmpty) {
        final stockDoc = stockQuery.docs.first;
        final currentQty = stockDoc['qty'] ?? 0;
        batch.update(stockDoc.reference, {'qty': currentQty + oldQty});
      }
    }

    // Step 2: Check if new stock is available
    for (var item in items) {
      final productRef = item.productRef!;
      final stockQuery = await firestore
          .collection('stocks')
          .where('product_ref', isEqualTo: productRef)
          .where('warehouse_ref', isEqualTo: warehouseRef)
          .limit(1)
          .get();

      if (stockQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Stok tidak ditemukan untuk produk'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      final stockDoc = stockQuery.docs.first;
      final currentQty = stockDoc['qty'] ?? 0;

      if (item.qty > currentQty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Stok tidak cukup untuk produk (${item.qty} > $currentQty)'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Deduct new stock
      batch.update(stockDoc.reference, {'qty': currentQty - item.qty});
    }

    // Step 3: Delete old details
    for (var doc in oldDetails.docs) {
      batch.delete(doc.reference);
    }

    // Step 4: Add new details
    for (var item in items) {
      batch.set(detailsRef.doc(), item.toMap());
    }

    // Step 5: Update invoice metadata
    batch.update(widget.invoiceRef, {
      'post_date': postDate.toIso8601String(),
      'customer_store_ref': chosenStore,
      'warehouse_ref': chosenWarehouse,
      'salesman_ref': chosenSalesman,
      'description': descCtrl.text.trim(),
      'item_total': itemCount,
      'grandtotal': totalAmt,
      'updated_at': DateTime.now(),
    });

    await batch.commit();

    if (mounted) Navigator.pop(context, 'updated');
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: pastelBlue,
      appBar: AppBar(title: const Text('Edit Faktur')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(children: [
          Text('No. Faktur: $invoiceNo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButton<DocumentReference>(
                value: chosenStore,
                hint: const Text('Pilih Customer'),
                items: stores
                    .map((d) => DropdownMenuItem(value: d.reference, child: Text(d['name'])))
                    .toList(),
                onChanged: (v) => setState(() => chosenStore = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<DocumentReference>(
                value: chosenSalesman,
                hint: const Text('Pilih Salesman'),
                items: salesmen
                    .map((d) => DropdownMenuItem(value: d.reference, child: Text(d['name'])))
                    .toList(),
                onChanged: (v) => setState(() => chosenSalesman = v),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButton<DocumentReference>(
                value: chosenWarehouse,
                hint: const Text('Pilih Gudang'),
                items: warehouses
                    .map((d) => DropdownMenuItem(value: d.reference, child: Text(d['name'])))
                    .toList(),
                onChanged: (v) => setState(() => chosenWarehouse = v),
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () async {
                final dt = await showDatePicker(
                  context: ctx,
                  initialDate: postDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (dt != null) setState(() => postDate = dt);
              },
              child: Text(DateFormat('yyyy-MM-dd').format(postDate)),
            ),
          ]),
          const Divider(height: 24),
          const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...items.asMap().entries.map((e) {
            final i = e.value;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: DropdownButton<DocumentReference>(
                        value: i.productRef,
                        hint: const Text('Produk'),
                        items: products
                            .map((p) => DropdownMenuItem(value: p.reference, child: Text(p['name'])))
                            .toList(),
                        onChanged: (v) => setState(() {
                          i.productRef = v;
                          final match = products.firstWhere((x) => x.reference == v);
                          i.price = match['default_price'] ?? 0;
                        }),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeItem(e.key),
                    ),
                  ]),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: i.qty.toString(),
                        decoration: const InputDecoration(labelText: 'Qty'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) async {
                          final val = int.tryParse(v) ?? 1;
                          final stock = await _getAvailableStock(i.productRef!);
                          final maxQty = stock + i.originalQty; 
                          if (val <= maxQty) {
                            setState(() => i.qty = val);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Qty melebihi stok ($maxQty)'),
                              backgroundColor: Colors.red,
                            ));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: i.price.toString(),
                        decoration: const InputDecoration(labelText: 'Harga'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() {
                          i.price = int.tryParse(v) ?? 0;
                        }),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text('Subtotal: ${fmt.format(i.subtotal)}', style: const TextStyle(fontSize: 16)),
                ]),
              ),
            );
          }),
          TextButton.icon(
            icon: const Icon(Icons.add, color: Colors.black54),
            label: const Text('Tambah Item', style: TextStyle(color: Colors.black87)),
            onPressed: _addItem,
          ),
          const Divider(height: 24),
          Text('Total Items: $itemCount'),
          Text('Total Bayar: ${fmt.format(totalAmt)}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: primaryBlue, padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _submit,
            child: const Text('Simpan', style: TextStyle(fontSize: 16)),
          ),
        ]),
      ),
    );
  }
}

class _Item {
  DocumentReference? productRef;
  int qty = 1, price = 0;
  int originalQty = 0; // 👈 added this
  final List<DocumentSnapshot> products;

  _Item({required this.products});

  factory _Item.fromMap(Map<String, dynamic> data, List<DocumentSnapshot> products) {
    final qty = data['qty'] ?? 1;
    return _Item(products: products)
      ..productRef = data['product_ref'] as DocumentReference?
      ..qty = qty
      ..originalQty = qty // 👈 store original delivery quantity
      ..price = data['price'] ?? 0;
  }

  int get subtotal => qty * price;

  Map<String, dynamic> toMap() => {
        'product_ref': productRef,
        'qty': qty,
        'price': price,
        'unit_name': 'pcs',
        'subtotal': subtotal,
      };
}
