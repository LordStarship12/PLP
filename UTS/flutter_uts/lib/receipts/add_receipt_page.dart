import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddReceiptPage extends StatefulWidget {
  const AddReceiptPage({super.key});

  @override
  State<AddReceiptPage> createState() => _AddReceiptPageState();
}

class _AddReceiptPageState extends State<AddReceiptPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _formNumberController = TextEditingController();
  DateTime? _selectedPostDate;
  final TextEditingController _postDateController = TextEditingController();

  DocumentReference? _selectedSupplier;
  DocumentReference? _selectedWarehouse;
  List<DocumentSnapshot> _suppliers = [];
  List<DocumentSnapshot> _warehouses = [];
  List<DocumentSnapshot> _products = [];

  final List<_DetailItem> _productDetails = [];

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
    if (storeRefPath == null) return;
    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);

    final suppliers = await FirebaseFirestore.instance.collection('suppliers').where('customer_ref', isEqualTo: storeRef).get();
    final warehouses = await FirebaseFirestore.instance.collection('warehouses').where('customer_ref', isEqualTo: storeRef).get();
    final products = await FirebaseFirestore.instance.collection('products').where('customer_ref', isEqualTo: storeRef).get();

    final generatedFormNo = await _generateFormNumber(); 

    setState(() {
      _suppliers = suppliers.docs;
      _warehouses = warehouses.docs;
      _products = products.docs;
      _formNumberController.text = generatedFormNo;
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
        _productDetails.isEmpty) {return;}
        
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Receipt berhasil ditambah.")),
    );


    if (mounted) Navigator.pop(context);
  }

  void _addProductRow() {
    setState(() {
      _productDetails.add(_DetailItem(products: _products));
    });
  }

  void _removeProductRow(int index) {
    setState(() {
      _productDetails.removeAt(index);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Receipt')),
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
                      decoration: InputDecoration(labelText: 'No. Form'),
                      readOnly: true,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<DocumentReference>(
                      items: _suppliers.map((doc) {
                        return DropdownMenuItem(
                          value: doc.reference,
                          child: Text(doc['name']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedSupplier = value),
                      decoration: InputDecoration(labelText: "Supplier"),
                      validator: (value) => value == null ? 'Pilih supplier' : null,
                    ),
                    DropdownButtonFormField<DocumentReference>(
                      items: _warehouses.map((doc) {
                        return DropdownMenuItem(
                          value: doc.reference,
                          child: Text(doc['name']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedWarehouse = value),
                      decoration: InputDecoration(labelText: "Warehouse"),
                      validator: (value) => value == null ? 'Pilih warehouse' : null,
                    ),
                    SizedBox(height: 24),
                    TextFormField(
                      controller: _postDateController,
                      decoration: InputDecoration(labelText: 'Tanggal Post'),
                      readOnly: true,
                      onTap: () => _selectPostDate(context),
                      validator: (value) => value == null || value.isEmpty ? 'Pilih tanggal' : null,
                    ),
                    SizedBox(height: 16),
                    Text("Detail Produk", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
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
                                onChanged: (value) {
                                  setState(() {
                                    item.productRef = value;
                                    item.unitName = 'pcs';
                                    item.unitController.text = item.unitName;
                                    
                                    final selectedProduct = _products.firstWhere((doc) => doc.reference == value);
                                    final defaultPrice = selectedProduct['default_price'] ?? 0;
                                    item.priceController.text = defaultPrice.toString();
                                  });
                                },
                                decoration: InputDecoration(labelText: "Produk"),
                                validator: (value) => value == null ? 'Pilih produk' : null,
                              ),
                              TextFormField(
                                controller: item.priceController,
                                decoration: InputDecoration(labelText: "Harga"),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}), 
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
                      onPressed: _saveReceipt,
                      child: Text('Simpan Receipt'),
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

