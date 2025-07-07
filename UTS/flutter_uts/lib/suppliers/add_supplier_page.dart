import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddSupplierPage extends StatefulWidget {
  const AddSupplierPage({super.key});

  @override
  State<AddSupplierPage> createState() => _AddSupplierPageState();
}

class _AddSupplierPageState extends State<AddSupplierPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _supplierController = TextEditingController();

  final Color pastelBlue = const Color(0xFFE3F2FD);
  final Color primaryBlue = const Color(0xFF2196F3);

  void _saveSupplier() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      final storeRefPath = prefs.getString('customer_ref');
      if (storeRefPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Store reference not found.")),
        );
        return;
      }

      final storeRef = FirebaseFirestore.instance.doc(storeRefPath);

      await FirebaseFirestore.instance.collection('suppliers').add({
        'name': _supplierController.text.trim(),
        'customer_ref': storeRef,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Supplier berhasil ditambahkan.")),
      );

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelBlue,
      appBar: AppBar(title: const Text("Tambah Supplier")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Nama Supplier',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSupplier,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Simpan Supplier'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
