  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  class AddProductPage extends StatefulWidget{
    const AddProductPage({super.key});

    @override
    State<AddProductPage> createState() => _AddProductPageState();
  }

  class _AddProductPageState extends State<AddProductPage> {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _productController = TextEditingController();

    void _saveProduct() async {
      if (_formKey.currentState!.validate()) {
        final prefs = await SharedPreferences.getInstance();
        
        final storeRefPath = prefs.getString('store_ref');
        if (storeRefPath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Store reference not found.")),
          );
          return;
        }

        final storeRef = FirebaseFirestore.instance.doc(storeRefPath);

        await FirebaseFirestore.instance.collection('products').add({
          'name': _productController.text.trim(),
          'qty': 0,
          'store_ref': storeRef,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Product berhasil ditambahkan.")),
        );

        if (mounted) Navigator.pop(context);
      }
    }


    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text("Tambah Supplier")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _productController,
                  decoration: InputDecoration(labelText: 'Nama Produk'),
                  validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveProduct,
                  child: Text('Simpan Product'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

