import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class EditReceiptModal extends StatefulWidget {
  final DocumentReference receiptRef;
  final Map<String, dynamic> receiptData;

  const EditReceiptModal({
    super.key,
    required this.receiptRef,
    required this.receiptData,
  });

  @override
  State<EditReceiptModal> createState() => _EditReceiptModalState();
}

class _EditReceiptModalState extends State<EditReceiptModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _formNumberController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  DateTime? _selectedDate;

  DocumentReference? _selectedSupplier;
  DocumentReference? _selectedWarehouse;
  List<DocumentSnapshot> _suppliers = [];
  List<DocumentSnapshot> _warehouses = [];
  List<DocumentSnapshot> _products = [];

  final List<_DetailItem> _productDetails = [];

  final Color pastelBlue = const Color(0xFFE3F2FD);
  final Color primaryBlue = const Color(0xFF2196F3);

  final dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  int get itemTotal => _productDetails.fold(0, (sum, item) => sum + item.qty);
  int get grandTotal => _productDetails.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    _formNumberController.text = widget.receiptData['no_form'] ?? '';
    _selectedSupplier = widget.receiptData['supplier_ref'];
    _selectedWarehouse = widget.receiptData['warehouse_ref'];

    if (widget.receiptData['updated_at'] != null) {
      _selectedDate = (widget.receiptData['updated_at'] as Timestamp).toDate();
      _dateController.text = dateFormatter.format(_selectedDate!);
    }

    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('customer_ref');
    if (storeRefPath == null) return;
    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);

    final suppliers = await FirebaseFirestore.instance
        .collection('suppliers')
        .where('customer_ref', isEqualTo: storeRef)
        .get();
    final warehouses = await FirebaseFirestore.instance
        .collection('warehouses')
        .where('customer_ref', isEqualTo: storeRef)
        .get();
    final products = await FirebaseFirestore.instance
        .collection('products')
        .where('customer_ref', isEqualTo: storeRef)
        .get();
    final detailsSnapshot = await widget.receiptRef.collection('details').get();

    if (!mounted) return;
    setState(() {
      _suppliers = suppliers.docs;
      _warehouses = warehouses.docs;
      _products = products.docs;
      _productDetails.clear();
      for (var doc in detailsSnapshot.docs) {
        _productDetails.add(_DetailItem.fromMap(doc.data(), _products, doc.reference));
      }
    });
  }

  void _updateReceipt() async {
    if (!_formKey.currentState!.validate() ||
        _selectedSupplier == null ||
        _selectedWarehouse == null ||
        _productDetails.isEmpty) return;

    final detailsRef = widget.receiptRef.collection('details');
    final firestore = FirebaseFirestore.instance;

    final oldDetailsSnapshot = await detailsRef.get();
    final oldQuantities = <String, int>{};

    for (var doc in oldDetailsSnapshot.docs) {
      final data = doc.data();
      final productRef = (data['product_ref'] as DocumentReference).id;
      final qty = (data['qty'] ?? 0);
      oldQuantities[productRef] = (oldQuantities[productRef] ?? 0) + (qty as num).toInt();
    }

    for (var doc in oldDetailsSnapshot.docs) {
      await doc.reference.delete();
    }

    final newQuantities = <String, int>{};

    for (var item in _productDetails) {
      final refId = item.productRef!.id;
      newQuantities[refId] = (newQuantities[refId] ?? 0) + item.qty;

      await item.productRef!.update({'default_price': item.price});
      await detailsRef.add(item.toMap());
    }

    for (var productRefId in {...oldQuantities.keys, ...newQuantities.keys}) {
      final oldQty = oldQuantities[productRefId] ?? 0;
      final newQty = newQuantities[productRefId] ?? 0;
      final qtyDiff = newQty - oldQty;

      final stockQuery = await firestore
          .collection('stocks')
          .where('product_ref', isEqualTo: firestore.doc('products/$productRefId'))
          .where('warehouse_ref', isEqualTo: _selectedWarehouse)
          .limit(1)
          .get();

      final productDocRef = firestore.doc('products/$productRefId');

      if (stockQuery.docs.isNotEmpty) {
        final stockDoc = stockQuery.docs.first.reference;
        await firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(stockDoc);
          final currentQty = snapshot['qty'] ?? 0;
          transaction.update(stockDoc, {'qty': currentQty + qtyDiff});
        });
      } else {
        await firestore.collection('stocks').add({
          'product_ref': firestore.doc('products/$productRefId'),
          'warehouse_ref': _selectedWarehouse,
          'qty': qtyDiff,
        });
      }

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(productDocRef);
        final currentQty = snapshot['qty'] ?? 0;
        transaction.update(productDocRef, {'qty': currentQty + qtyDiff});
      });
    }

    await widget.receiptRef.update({
      'no_form': _formNumberController.text.trim(),
      'supplier_ref': _selectedSupplier,
      'warehouse_ref': _selectedWarehouse,
      'item_total': itemTotal,
      'grandtotal': grandTotal,
      'updated_at': DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Receipt berhasil diedit.")),
    );

    if (mounted) Navigator.pop(context, 'updated');
  }

  void _removeProductRow(int index) {
    setState(() => _productDetails.removeAt(index));
  }

  void _addProductRow() {
    setState(() => _productDetails.add(_DetailItem(products: _products)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelBlue,
      appBar: AppBar(title: const Text('Edit Receipt')),
      body: _products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(children: [
                  TextFormField(
                    controller: _formNumberController,
                    decoration: const InputDecoration(labelText: 'No. Form'),
                    validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    readOnly: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DocumentReference>(
                    value: _selectedSupplier,
                    icon: const SizedBox.shrink(),
                    items: _suppliers.map((doc) => DropdownMenuItem(
                      value: doc.reference,
                      child: Text(doc['name']),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedSupplier = v),
                    decoration: const InputDecoration(labelText: 'Supplier'),
                    validator: (v) => v == null ? 'Pilih supplier' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DocumentReference>(
                    value: _selectedWarehouse,
                    icon: const SizedBox.shrink(),
                    items: _warehouses.map((doc) => DropdownMenuItem(
                      value: doc.reference,
                      child: Text(doc['name']),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedWarehouse = v),
                    decoration: const InputDecoration(labelText: 'Warehouse'),
                    validator: (v) => v == null ? 'Pilih warehouse' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Tanggal'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                          _dateController.text = dateFormatter.format(picked);
                        });
                      }
                    },
                    validator: (v) => v == null || v.isEmpty ? 'Pilih tanggal' : null,
                  ),
                  const SizedBox(height: 24),
                  const Text('Detail Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ..._productDetails.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<DocumentReference>(
                              value: item.productRef,
                              icon: const SizedBox.shrink(),
                              items: _products.map((doc) {
                                return DropdownMenuItem(
                                  value: doc.reference,
                                  child: Text(doc['name']),
                                );
                              }).toList(),
                              onChanged: (v) {
                                setState(() {
                                  item.productRef = v;
                                  item.unitName = 'pcs';
                                });
                              },
                              decoration: const InputDecoration(labelText: 'Produk'),
                              validator: (v) => v == null ? 'Pilih produk' : null,
                            ),
                            TextFormField(
                              initialValue: item.price.toString(),
                              decoration: const InputDecoration(labelText: 'Harga'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(() => item.price = int.tryParse(v) ?? 0),
                              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                            ),
                            TextFormField(
                              initialValue: item.qty.toString(),
                              decoration: const InputDecoration(labelText: 'Jumlah'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(() => item.qty = int.tryParse(v) ?? 1),
                              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                            ),
                            const SizedBox(height: 8),
                            Text("Satuan: ${item.unitName}"),
                            Text("Subtotal: ${currencyFormatter.format(item.subtotal)}"),
                            TextButton.icon(
                              onPressed: () => _removeProductRow(index),
                              icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                              label: const Text("Hapus Produk", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Produk'),
                    onPressed: _addProductRow,
                  ),
                  const Divider(height: 32),
                  Text("Item Total: $itemTotal"),
                  Text("Grand Total: ${currencyFormatter.format(grandTotal)}"),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _updateReceipt,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Update Receipt'),
                  ),
                ]),
              ),
            ),
    );
  }
}

class _DetailItem {
  DocumentReference? productRef;
  int price;
  int qty;
  String unitName;
  final List<DocumentSnapshot> products;
  final DocumentReference? docRef;

  _DetailItem({
    this.productRef,
    this.price = 0,
    this.qty = 1,
    this.unitName = 'unit',
    required this.products,
    this.docRef,
  });

  factory _DetailItem.fromMap(Map<String, dynamic> data, List<DocumentSnapshot> products, DocumentReference ref) {
    return _DetailItem(
      productRef: data['product_ref'],
      price: data['price'],
      qty: data['qty'],
      unitName: data['unit_name'] ?? 'unit',
      products: products,
      docRef: ref,
    );
  }

  int get subtotal => price * qty;

  Map<String, dynamic> toMap() {
    return {
      'product_ref': productRef,
      'price': price,
      'qty': qty,
      'unit_name': unitName,
      'subtotal': subtotal,
    };
  }
}