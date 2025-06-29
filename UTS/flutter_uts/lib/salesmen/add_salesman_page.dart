import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddSalesmanPage extends StatefulWidget {
  const AddSalesmanPage({super.key});

  @override
  State<AddSalesmanPage> createState() => _AddSalesmanPageState();
}

class _AddSalesmanPageState extends State<AddSalesmanPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  Future<void> _saveSalesman() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final storeRefPath = prefs.getString('customer_ref');

      if (storeRefPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Customer reference not found.")),
        );
        return;
      }

      final storeRef = FirebaseFirestore.instance.doc(storeRefPath);

      await FirebaseFirestore.instance.collection('salesmen').add({
        'name': _nameController.text.trim(),
        'area': _areaController.text.trim(),
        'customer_ref': storeRef,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Salesman berhasil ditambahkan.")),
      );

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tambah Salesman")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nama Salesman'),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _areaController,
                decoration: InputDecoration(labelText: 'Area Penjualan'),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSalesman,
                child: Text('Simpan Salesman'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
