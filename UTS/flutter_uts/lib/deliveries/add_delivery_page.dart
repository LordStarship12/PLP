import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddDeliveryPage extends StatefulWidget {
  const AddDeliveryPage({super.key});

  @override
  State<AddDeliveryPage> createState() => _AddDeliveryPageState();
}

class _AddDeliveryPageState extends State<AddDeliveryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _formNumberController = TextEditingController();
  DateTime? _selectedPostDate;
  final TextEditingController _postDateController = TextEditingController();

  DocumentReference? _selectedStore;
  DocumentReference? _selectedWarehouse;
  List<DocumentSnapshot> _stores = [];
  List<DocumentSnapshot> _warehouses = [];
  List<DocumentSnapshot> _products = [];

  final List<_DetailItem> _productDetails = [];

  int get itemTotal => _productDetails.fold(0, (sum, item) => sum + item.qty);
  int get grandTotal => _productDetails.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
    _generateFormNumber();
  }

  Future<void> _fetchDropdownData() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('store_ref');
    if (storeRefPath == null) return;
    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);

    final storesQuery = await FirebaseFirestore.instance.collection('stores').get();
    final stores = storesQuery.docs.where((doc) => doc.reference.path != storeRef.path).toList();

    final warehouses = await FirebaseFirestore.instance.collection('warehouses').where('store_ref', isEqualTo: storeRef).get();
    final products = await FirebaseFirestore.instance.collection('products').where('store_ref', isEqualTo: storeRef).get();

    final generatedFormNo = await _generateFormNumber(); 
    
    setState(() {
      _stores = stores;
      _warehouses = warehouses.docs;
      _products = products.docs;
      _formNumberController.text = generatedFormNo;
    });
  }

  Future<String> _generateFormNumber() async {
    final receipts = await FirebaseFirestore.instance
        .collection('deliveries')
        .orderBy('created_at', descending: true)
        .get(); 

    int maxNumber = 0;
    final base = 'TTJ22100034';

    for (var doc in receipts.docs) {
      final lastForm = doc['no_form'];
      final parts = lastForm.split('_');
      if (parts.length == 2) {
        final number = int.tryParse(parts[1]) ?? 0;
        if (number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    final nextNumber = maxNumber + 1;
    return '${base}_$nextNumber';
  }

  Future<void> _saveDelivery() async {
    if (!_formKey.currentState!.validate() ||
        _selectedStore == null ||
        _selectedWarehouse == null ||
        _productDetails.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('store_ref');
    if (storeRefPath == null) return;
    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);

    final deliveryData = {
      'no_form': _formNumberController.text.trim(),
      'grandtotal': grandTotal,
      'item_total': itemTotal,
      'post_date': _selectedPostDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'created_at': DateTime.now(),
      'store_ref': storeRef,
      'destination_store_ref': _selectedStore,
      'warehouse_ref': _selectedWarehouse,
      'synced': true,
    };

    final deliveryDoc = await FirebaseFirestore.instance.collection('deliveries').add(deliveryData);

    for (final item in _productDetails) {
      await deliveryDoc.collection('details').add(item.toMap());

      if (item.productRef != null && _selectedWarehouse != null) {
        final stockQuery = await FirebaseFirestore.instance
            .collection('stocks')
            .where('product_ref', isEqualTo: item.productRef)
            .where('warehouse_ref', isEqualTo: _selectedWarehouse)
            .limit(1)
            .get();

        if (stockQuery.docs.isNotEmpty) {
          final stockDoc = stockQuery.docs.first;
          final stockRef = stockDoc.reference;
          final stockData = stockDoc.data();
          final stockQty = stockData['qty'] ?? 0;

          if (stockQty == item.qty) {
            await stockRef.delete();
          } else if (stockQty > item.qty) {
            await stockRef.update({'qty': stockQty - item.qty});
          } else {
            print('Warning: Stock qty (${stockQty}) < delivery qty (${item.qty}) for product ${item.productRef!.id}');
          }
        } else {
          print('Warning: No stock found for product ${item.productRef!.id} in selected warehouse');
        }

        final productSnap = await item.productRef!.get();
        final currentQty = productSnap['qty'] ?? 0;
        await item.productRef!.update({
          'qty': currentQty - item.qty,
        });
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Delivery berhasil ditambah.")),
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
      appBar: AppBar(title: Text('Tambah Delivery')),
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
                      items: _stores.map((doc) {
                        return DropdownMenuItem(
                          value: doc.reference,
                          child: Text(doc['name']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedStore = value),
                      decoration: InputDecoration(labelText: "Store Tujuan"),
                      validator: (value) => value == null ? 'Pilih store' : null,
                    ),
                    DropdownButtonFormField<DocumentReference>(
                      items: _warehouses.map((doc) {
                        return DropdownMenuItem(
                          value: doc.reference,
                          child: Text(doc['name']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedWarehouse = value),
                      decoration: InputDecoration(labelText: "Warehouse Asal"),
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
                                onChanged: (value) async {
                                  setState(() {
                                    item.productRef = value;
                                    item.unitName = 'pcs';
                                    item.unitController.text = item.unitName;
                                    item.availableStock = 0;
                                  });
                                
                                  if (value != null && _selectedWarehouse != null) {
                                    final stockQuery = await FirebaseFirestore.instance
                                        .collection('stocks')
                                        .where('product_ref', isEqualTo: value)
                                        .where('warehouse_ref', isEqualTo: _selectedWarehouse)
                                        .limit(1)
                                        .get();
                                
                                    int stockQty = 0;
                                    if (stockQuery.docs.isNotEmpty) {
                                      final stockData = stockQuery.docs.first.data();
                                      stockQty = stockData['qty'] ?? 0;
                                    }
                                
                                    setState(() {
                                      item.availableStock = stockQty;
                                    });
                                  }
                                },
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
                                decoration: InputDecoration(
                                  labelText: "Jumlah",
                                  suffixText: "/ Stok: ${item.availableStock}",
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  final inputQty = int.tryParse(val) ?? 1;
                                  setState(() {
                                    item.qty = inputQty;
                                  });
                                  if (inputQty > item.availableStock) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Qty melebihi stok tersedia!")),
                                    );
                                  }
                                },
                                validator: (val) {
                                  final inputQty = int.tryParse(val ?? '') ?? 0;
                                  if (val!.isEmpty) return 'Wajib diisi';
                                  if (inputQty > item.availableStock) return 'Qty melebihi stok';
                                  return null;
                                },
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
                      onPressed: _saveDelivery,
                      child: Text('Simpan Delivery'),
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
  int price = 0;
  int qty = 1;
  String unitName = 'unit';
  int availableStock = 0;
  TextEditingController unitController = TextEditingController();
  final List<DocumentSnapshot> products;

  _DetailItem({required this.products});

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
