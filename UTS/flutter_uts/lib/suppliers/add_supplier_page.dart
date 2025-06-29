  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  class AddSupplierPage extends StatefulWidget{
    const AddSupplierPage({super.key});

    @override
    State<AddSupplierPage> createState() => _AddSupplierPageState();
  }

  class _AddSupplierPageState extends State<AddSupplierPage> {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _supplierController = TextEditingController();

    void _saveSupplier() async {
      if (_formKey.currentState!.validate()) {
        final prefs = await SharedPreferences.getInstance();
        
        final storeRefPath = prefs.getString('customer_ref');
        if (storeRefPath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Store reference not found.")),
          );
          return;
        }

        final storeRef = FirebaseFirestore.instance.doc(storeRefPath);

        await FirebaseFirestore.instance.collection('suppliers').add({
          'name': _supplierController.text.trim(),
          'customer_ref': storeRef,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Supplier berhasil ditambahkan.")),
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
                  controller: _supplierController,
                  decoration: InputDecoration(labelText: 'Nama Supplier'),
                  validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveSupplier,
                  child: Text('Simpan Supplier'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

