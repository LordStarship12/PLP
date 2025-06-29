import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditDeliveryModal extends StatefulWidget {
  final DocumentReference invoiceRef;
  final Map<String, dynamic> invoiceData;

  const EditDeliveryModal({
    super.key,
    required this.invoiceRef,
    required this.invoiceData,
  });

  @override
  State<EditDeliveryModal> createState() => _EditDeliveryModalState();
}

class _EditDeliveryModalState extends State<EditDeliveryModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _formNumberController = TextEditingController();
  final TextEditingController _postDateController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _selectedPostDate;
  DocumentReference? _selectedDestinationStore;
  DocumentReference? _selectedWarehouse;
  List<DocumentSnapshot> _stores = [];
  List<DocumentSnapshot> _warehouses = [];
  List<DocumentSnapshot> _products = [];
  final List<_DetailItem> _productDetails = [];

  bool _isCredit = false;
  int _creditDuration = 3;
  bool _isPaid = false;

  int get itemTotal => _productDetails.fold(0, (sum, item) => sum + item.qty);
  int get grandTotal => _productDetails.fold(0, (sum, item) => sum + item.subtotal);
  double get installmentPerMonth => _isCredit ? grandTotal / _creditDuration : 0;

  @override
  void initState() {
    super.initState();
    _formNumberController.text = widget.invoiceData['no_faktur'] ?? '';
    _selectedDestinationStore = null;
    _selectedWarehouse = widget.invoiceData['warehouse_ref'];
    _isCredit = widget.invoiceData['is_credit'] ?? false;
    _creditDuration = widget.invoiceData['credit_duration'] ?? 3;
    _isPaid = widget.invoiceData['is_paid'] ?? false;
    _keteranganController.text = widget.invoiceData['keterangan'] ?? '';
    _descriptionController.text = widget.invoiceData['description'] ?? '';

    final postDateStr = widget.invoiceData['post_date'];
    if (postDateStr != null) {
      _selectedPostDate = DateTime.tryParse(postDateStr);
      if (_selectedPostDate != null) {
        _postDateController.text =
            "${_selectedPostDate!.year}-${_selectedPostDate!.month.toString().padLeft(2, '0')}-${_selectedPostDate!.day.toString().padLeft(2, '0')}";
      }
    }

    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('customer_ref');
    if (storeRefPath == null) return;
    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);

    final stores = await FirebaseFirestore.instance.collection('customers').get();
    final warehouses = await FirebaseFirestore.instance.collection('warehouses').where('customer_ref', isEqualTo: storeRef).get();
    final products = await FirebaseFirestore.instance.collection('products').where('customer_ref', isEqualTo: storeRef).get();
    final detailsSnapshot = await widget.invoiceRef.collection('details').get();

    if (!mounted) return;
    setState(() {
      _stores = stores.docs;
      _warehouses = warehouses.docs;
      _products = products.docs;
      _productDetails.clear();
      for (var doc in detailsSnapshot.docs) {
        _productDetails.add(_DetailItem.fromMap(doc.data(), _products, doc.reference));
      }
    });
  }

  Future<void> _selectPostDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPostDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedPostDate = picked;
        _postDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _updateInvoice() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDestinationStore == null ||
        _selectedWarehouse == null ||
        _productDetails.isEmpty) return;

    final detailsRef = widget.invoiceRef.collection('details');
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
          transaction.update(stockDoc, {'qty': currentQty - qtyDiff});
        });
      } else {
        await firestore.collection('stocks').add({
          'product_ref': firestore.doc('products/$productRefId'),
          'warehouse_ref': _selectedWarehouse,
          'qty': -qtyDiff,
        });
      }

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(productDocRef);
        final currentQty = snapshot['qty'] ?? 0;
        transaction.update(productDocRef, {'qty': currentQty - qtyDiff});
      });
    }

    await widget.invoiceRef.update({
      'no_faktur': _formNumberController.text.trim(),
      'customer_store_ref': _selectedDestinationStore,
      'warehouse_ref': _selectedWarehouse,
      'item_total': itemTotal,
      'grandtotal': grandTotal,
      'is_credit': _isCredit,
      'credit_duration': _isCredit ? _creditDuration : 0,
      'installment': _isCredit ? installmentPerMonth : 0,
      'is_paid': _isPaid,
      'post_date': _selectedPostDate?.toIso8601String(),
      'keterangan': _keteranganController.text.trim(),
      'description': _descriptionController.text.trim(),
      'updated_at': DateTime.now(),
    });

    if (mounted) {
      Navigator.pop(context, 'updated');
    }
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
      appBar: AppBar(title: Text('Edit Sales Invoice')),
      body: _products.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _formNumberController,
                      decoration: InputDecoration(labelText: 'No. Faktur'),
                      validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    DropdownButtonFormField<DocumentReference>(
                      value: _selectedDestinationStore,
                      items: _stores.map((doc) {
                        return DropdownMenuItem(
                          value: doc.reference,
                          child: Text(doc['name']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedDestinationStore = value),
                      decoration: InputDecoration(labelText: 'Store (Customer)'),
                      validator: (value) => value == null ? 'Pilih store' : null,
                    ),
                    DropdownButtonFormField<DocumentReference>(
                      value: _selectedWarehouse,
                      items: _warehouses.map((doc) {
                        return DropdownMenuItem(
                          value: doc.reference,
                          child: Text(doc['name']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedWarehouse = value),
                      decoration: InputDecoration(labelText: 'Warehouse Asal'),
                      validator: (value) => value == null ? 'Pilih warehouse' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _postDateController,
                      readOnly: true,
                      decoration: InputDecoration(labelText: 'Tanggal Post'),
                      onTap: () => _selectPostDate(context),
                      validator: (value) => value == null || value.isEmpty ? 'Pilih tanggal' : null,
                    ),
                    CheckboxListTile(
                      value: _isCredit,
                      onChanged: (val) => setState(() => _isCredit = val!),
                      title: Text("Credit?"),
                    ),
                    if (_isCredit)
                      DropdownButtonFormField<int>(
                        value: _creditDuration,
                        items: [3, 6, 12].map((month) {
                          return DropdownMenuItem(
                            value: month,
                            child: Text("$month bulan"),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _creditDuration = val!),
                        decoration: InputDecoration(labelText: "Durasi Kredit"),
                      ),
                    if (_isCredit)
                      Text("Cicilan per bulan: ${installmentPerMonth.toStringAsFixed(2)}"),
                    CheckboxListTile(
                      value: _isPaid,
                      onChanged: (val) => setState(() => _isPaid = val!),
                      title: Text("Sudah Lunas?"),
                    ),
                    TextFormField(
                      controller: _keteranganController,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: 'Keterangan'),
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: 'Description'),
                    ),
                    SizedBox(height: 16),
                    Text("Detail Produk", style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._productDetails.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              DropdownButtonFormField<DocumentReference>(
                                value: item.productRef,
                                items: _products.map((doc) {
                                  return DropdownMenuItem(
                                    value: doc.reference,
                                    child: Text(doc['name']),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => item.productRef = value),
                                decoration: InputDecoration(labelText: "Produk"),
                                validator: (value) => value == null ? 'Pilih produk' : null,
                              ),
                              TextFormField(
                                initialValue: item.price.toString(),
                                decoration: InputDecoration(labelText: "Harga"),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => setState(() {
                                  item.price = int.tryParse(val) ?? 0;
                                }),
                                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                              ),
                              TextFormField(
                                initialValue: item.qty.toString(),
                                decoration: InputDecoration(labelText: "Jumlah"),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => setState(() {
                                  item.qty = int.tryParse(val) ?? 1;
                                }),
                                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                              ),
                              SizedBox(height: 8),
                              Text("Subtotal: ${item.subtotal}"),
                              SizedBox(height: 4),
                              TextButton.icon(
                                onPressed: () => _removeProductRow(index),
                                icon: Icon(Icons.remove_circle, color: Colors.red),
                                label: Text("Hapus Produk"),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    ElevatedButton.icon(
                      onPressed: _addProductRow,
                      icon: Icon(Icons.add),
                      label: Text('Tambah Produk'),
                    ),
                    SizedBox(height: 16),
                    Text("Item Total: $itemTotal"),
                    Text("Grand Total: $grandTotal"),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updateInvoice,
                      child: Text('Update Sales Invoice'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _DetailItem {
  DocumentReference? productRef;
  int price;
  int qty;
  final List<DocumentSnapshot> products;
  final DocumentReference? docRef;

  _DetailItem({this.productRef, this.price = 0, this.qty = 1, required this.products, this.docRef});

  factory _DetailItem.fromMap(Map<String, dynamic> data, List<DocumentSnapshot> products, DocumentReference ref) {
    return _DetailItem(
      productRef: data['product_ref'],
      price: data['price'],
      qty: data['qty'],
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
      'subtotal': subtotal,
    };
  }
}
