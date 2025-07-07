import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AddReceiptPage extends StatefulWidget {
  const AddReceiptPage({super.key});

  @override
  State<AddReceiptPage> createState() => _AddReceiptPageState();
}

class _AddReceiptPageState extends State<AddReceiptPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _formNumberController = TextEditingController();
  final TextEditingController _postDateController = TextEditingController();
  DateTime? _selectedPostDate;

  DocumentReference? _selectedSupplier;
  DocumentReference? _selectedWarehouse;

  List<DocumentSnapshot> _suppliers = [];
  List<DocumentSnapshot> _warehouses = [];
  List<DocumentSnapshot> _products = [];

  final List<_DetailItem> _productDetails = [];
  bool _loading = true;

  final pastelBlue = const Color(0xFFE3F2FD);
  final primaryBlue = const Color(0xFF2196F3);
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  int get itemTotal => _productDetails.fold(0, (sum, item) => sum + item.qty);
  int get grandTotal => _productDetails.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('customer_ref');
    if (storeRefPath == null || storeRefPath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store reference tidak ditemukan.')),
        );
        Navigator.pop(context);
      }
      return;
    }

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

    final generatedFormNo = await _generateFormNumber();

    setState(() {
      _suppliers = suppliers.docs;
      _warehouses = warehouses.docs;
      _products = products.docs;
      _formNumberController.text = generatedFormNo;
      _loading = false;
    });
  }

  Future<String> _generateFormNumber() async {
    final receipts = await FirebaseFirestore.instance
        .collection('purchaseGoodsReceipts')
        .orderBy('created_at', descending: true)
        .get();
    int nextNumber = 1;
    final base = 'TTB22100034';
    if (receipts.docs.isNotEmpty) {
      final lastForm = receipts.docs.first['no_form'];
      final parts = lastForm.split('_');
      if (parts.length == 2) {
        final number = int.tryParse(parts[1]) ?? 0;
        nextNumber = number + 1;
      }
    }
    return '${base}_$nextNumber';
  }

  Future<void> _saveReceipt() async {
    if (!_formKey.currentState!.validate() ||
        _selectedSupplier == null ||
        _selectedWarehouse == null ||
        _productDetails.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('customer_ref');
    if (storeRefPath == null) return;
    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);

    final receiptData = {
      'no_form': _formNumberController.text.trim(),
      'grandtotal': grandTotal,
      'item_total': itemTotal,
      'post_date': _selectedPostDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'created_at': DateTime.now(),
      'customer_ref': storeRef,
      'supplier_ref': _selectedSupplier,
      'warehouse_ref': _selectedWarehouse,
    };

    final receiptDoc = await FirebaseFirestore.instance.collection('purchaseGoodsReceipts').add(receiptData);

    for (final item in _productDetails) {
      await receiptDoc.collection('details').add(item.toMap());

      if (item.productRef != null) {
        final productSnap = await item.productRef!.get();
        final currentQty = productSnap['qty'] ?? 0;
        await item.productRef!.update({
          'qty': currentQty + item.qty,
        });
      }

      final stockQuery = await FirebaseFirestore.instance
          .collection('stocks')
          .where('customer_ref', isEqualTo: storeRef)
          .where('warehouse_ref', isEqualTo: _selectedWarehouse)
          .where('product_ref', isEqualTo: item.productRef)
          .get();

      if (stockQuery.docs.isNotEmpty) {
        final stockDoc = stockQuery.docs.first;
        final currentStock = stockDoc['qty'] ?? 0;
        await stockDoc.reference.update({'qty': currentStock + item.qty});
      } else {
        final stocksSnap = await FirebaseFirestore.instance
            .collection('stocks')
            .orderBy('id', descending: true)
            .limit(1)
            .get();

        final nextId = stocksSnap.docs.isNotEmpty
            ? (stocksSnap.docs.first['id'] ?? 0) + 1
            : 1;

        await FirebaseFirestore.instance.collection('stocks').add({
          'id': nextId,
          'customer_ref': storeRef,
          'warehouse_ref': _selectedWarehouse,
          'product_ref': item.productRef,
          'qty': item.qty,
        });
      }
    }

    if (mounted) Navigator.pop(context, 'saved');
  }

  void _addProductRow() => setState(() => _productDetails.add(_DetailItem(products: _products)));
  void _removeProductRow(int index) => setState(() => _productDetails.removeAt(index));

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
        _postDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelBlue,
      appBar: AppBar(title: const Text('Tambah Receipt')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('Tidak ada produk yang tersedia.'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: ListView(children: [
                      TextFormField(
                        controller: _formNumberController,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: 'No. Form'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<DocumentReference>(
                        value: _selectedSupplier,
                        icon: const SizedBox.shrink(),
                        items: _suppliers.map((doc) {
                          return DropdownMenuItem(
                            value: doc.reference,
                            child: Text(doc['name']),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedSupplier = value),
                        decoration: const InputDecoration(labelText: "Supplier"),
                        validator: (value) => value == null ? 'Pilih supplier' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<DocumentReference>(
                        value: _selectedWarehouse,
                        icon: const SizedBox.shrink(),
                        items: _warehouses.map((doc) {
                          return DropdownMenuItem(
                            value: doc.reference,
                            child: Text(doc['name']),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedWarehouse = value),
                        decoration: const InputDecoration(labelText: "Warehouse"),
                        validator: (value) => value == null ? 'Pilih warehouse' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _postDateController,
                        readOnly: true,
                        onTap: () => _selectPostDate(context),
                        decoration: const InputDecoration(labelText: 'Tanggal Post'),
                        validator: (value) => value == null || value.isEmpty ? 'Pilih tanggal' : null,
                      ),
                      const SizedBox(height: 24),
                      const Text("Detail Produk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ..._productDetails.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(children: [
                              DropdownButtonFormField<DocumentReference>(
                                value: item.productRef,
                                icon: const SizedBox.shrink(),
                                items: _products.map((doc) {
                                  return DropdownMenuItem(
                                    value: doc.reference,
                                    child: Text(doc['name']),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    item.productRef = value;
                                    item.unitName = 'pcs';
                                    item.unitController.text = 'pcs';
                                    final prod = _products.firstWhere((d) => d.reference == value);
                                    final price = prod['default_price'] ?? 0;
                                    item.priceController.text = price.toString();
                                  });
                                },
                                decoration: const InputDecoration(labelText: "Produk"),
                                validator: (value) => value == null ? 'Pilih produk' : null,
                              ),
                              TextFormField(
                                controller: item.priceController,
                                decoration: const InputDecoration(labelText: "Harga"),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                              ),
                              TextFormField(
                                initialValue: item.qty.toString(),
                                decoration: const InputDecoration(labelText: "Jumlah"),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => setState(() {
                                  item.qty = int.tryParse(val) ?? 1;
                                }),
                                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                              ),
                              const SizedBox(height: 8),
                              Text("Subtotal: ${currencyFormat.format(item.subtotal)}"),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => _removeProductRow(index),
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                label: const Text("Hapus Produk", style: TextStyle(color: Colors.red)),
                              ),
                            ]),
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: _addProductRow,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Produk'),
                      ),
                      const Divider(height: 24),
                      Text("Total Item: $itemTotal"),
                      Text("Grand Total: ${currencyFormat.format(grandTotal)}", style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _saveReceipt,
                        child: const Text('Simpan Receipt', style: TextStyle(fontSize: 16)),
                      ),
                    ]),
                  ),
                ),
    );
  }
}

class _DetailItem {
  DocumentReference? productRef;
  int qty = 1;
  String unitName = 'unit';
  final List<DocumentSnapshot> products;
  TextEditingController priceController = TextEditingController();
  TextEditingController unitController = TextEditingController();

  _DetailItem({required this.products});

  int get price => int.tryParse(priceController.text) ?? 0;
  int get subtotal => price * qty;

  Map<String, dynamic> toMap() {
    return {
      'product_ref': productRef,
      'price': price,
      'qty': qty,
      'unit_name': unitController.text.trim(),
      'subtotal': subtotal,
    };
  }
}
