import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddDetailPage extends StatefulWidget {
  const AddDetailPage({super.key});

  @override
  _AddDetailPageState createState() => _AddDetailPageState();
}

class _AddDetailPageState extends State<AddDetailPage> {
  final _formKey = GlobalKey<FormState>();
  DocumentReference? _selectedProduct;
  int _price = 0;
  int _qty = 1;
  String _unitName = 'pcs';
  int _subtotal = 0;

  List<DocumentSnapshot> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final productsSnap = await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      _products = productsSnap.docs;
    });
  }

  void _calculateSubtotal() {
    setState(() {
      _subtotal = _price * _qty;
    });
  }

  void _saveDetail() async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) return;

    await FirebaseFirestore.instance.collection('details').add({
      'product_ref': _selectedProduct,
      'price': _price,
      'qty': _qty,
      'unit_name': _unitName,
      'subtotal': _subtotal,
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tambah Detail Produk")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<DocumentReference>(
                items: _products.map((doc) {
                  return DropdownMenuItem(
                    value: doc.reference,
                    child: Text(doc['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  final id = value!.id;
                  setState(() {
                    _selectedProduct = value;
                    _unitName = (id == '1') ? 'pcs' : (id == '2') ? 'dus' : 'unit';
                  });
                },
                decoration: InputDecoration(labelText: "Produk"),
                validator: (value) => value == null ? 'Pilih produk' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Harga"),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _price = int.tryParse(value) ?? 0;
                  _calculateSubtotal();
                },
                validator: (value) => value!.isEmpty ? 'Masukkan harga' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Jumlah"),
                keyboardType: TextInputType.number,
                initialValue: '1',
                onChanged: (value) {
                  _qty = int.tryParse(value) ?? 1;
                  _calculateSubtotal();
                },
                validator: (value) => value!.isEmpty ? 'Masukkan jumlah' : null,
              ),
              SizedBox(height: 16),
              Text("Satuan: $_unitName"),
              Text("Subtotal: $_subtotal"),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveDetail,
                child: Text('Simpan Detail'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
