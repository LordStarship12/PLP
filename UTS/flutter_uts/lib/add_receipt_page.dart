import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddReceiptPage extends StatefulWidget {
  const AddReceiptPage({super.key});

  @override
  _AddReceiptPageState createState() => _AddReceiptPageState();
}

class _AddReceiptPageState extends State<AddReceiptPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _formNumberController = TextEditingController();
  final TextEditingController _grandTotalController = TextEditingController();
  final TextEditingController _itemTotalController = TextEditingController();

  DocumentReference? _selectedSupplier;
  DocumentReference? _selectedWarehouse;

  List<DocumentSnapshot> _suppliers = [];
  List<DocumentSnapshot> _warehouses = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    final suppliersSnap = await FirebaseFirestore.instance.collection('suppliers').get();
    final warehousesSnap = await FirebaseFirestore.instance.collection('warehouses').get();

    setState(() {
      _suppliers = suppliersSnap.docs;
      _warehouses = warehousesSnap.docs;
    });
  }

  void _saveReceipt() async {
    if (!_formKey.currentState!.validate() || _selectedSupplier == null || _selectedWarehouse == null) return;

    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('store_ref');
    if (storeRefPath == null) return;
    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);

    await FirebaseFirestore.instance.collection('purchaseGoodsReceipts').add({
      'no_form': _formNumberController.text.trim(),
      'grandtotal': int.parse(_grandTotalController.text.trim()),
      'item_total': int.parse(_itemTotalController.text.trim()),
      'post_date': DateTime.now().toIso8601String(),
      'created_at': DateTime.now(),
      'store_ref': storeRef,
      'supplier_ref': _selectedSupplier,
      'warehouse_ref': _selectedWarehouse,
      'synced': true,
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tambah Receipt")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _formNumberController,
                decoration: InputDecoration(labelText: "No. Form"),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _grandTotalController,
                decoration: InputDecoration(labelText: "Grand Total"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _itemTotalController,
                decoration: InputDecoration(labelText: "Item Total"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<DocumentReference>(
                items: _suppliers.map((doc) {
                  return DropdownMenuItem(
                    value: doc.reference,
                    child: Text(doc['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSupplier = value;
                  });
                },
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
                onChanged: (value) {
                  setState(() {
                    _selectedWarehouse = value;
                  });
                },
                decoration: InputDecoration(labelText: "Warehouse"),
                validator: (value) => value == null ? 'Pilih warehouse' : null,
              ),
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
