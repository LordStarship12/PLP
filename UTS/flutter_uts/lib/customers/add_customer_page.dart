import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();

  Future<void> _saveCustomer() async {
    final username = _usernameController.text.trim();
    final storeName = _storeNameController.text.trim();

    if (!_formKey.currentState!.validate()) return;

    final query = await FirebaseFirestore.instance
        .collection('customers')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username sudah dipakai.")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('customers').add({
      'username': _usernameController.text.trim(),
      'password': BCrypt.hashpw(_passwordController.text.trim(), BCrypt.gensalt()),
      'name': storeName,
      'created_at': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Customer berhasil ditambahkan.")),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Customer")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _storeNameController,
                decoration: const InputDecoration(labelText: 'Nama Toko'),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveCustomer,
                child: const Text('Simpan Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
