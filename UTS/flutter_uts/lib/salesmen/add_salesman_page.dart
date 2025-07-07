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

  final Color pastelBlue = const Color(0xFFE3F2FD);
  final Color primaryBlue = const Color(0xFF2196F3);

  Future<void> _saveSalesman() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final storeRefPath = prefs.getString('customer_ref');

      if (storeRefPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Customer reference not found.")),
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
        const SnackBar(content: Text("Salesman berhasil ditambahkan.")),
      );

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelBlue,
      appBar: AppBar(title: const Text("Tambah Salesman")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Salesman',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'Area Penjualan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSalesman,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Simpan Salesman'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
