import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSupplierModal extends StatefulWidget {
  final DocumentReference supplierRef;

  const EditSupplierModal({
    super.key,
    required this.supplierRef,
  });

  @override
  State<EditSupplierModal> createState() => _EditSupplierModalState();
}

class _EditSupplierModalState extends State<EditSupplierModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _supplierNameController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSupplierData();
  }

  Future<void> _loadSupplierData() async {
    try {
      final doc = await widget.supplierRef.get();
      final data = doc.data() as Map<String, dynamic>?;
      _supplierNameController.text = data?['name'] ?? '';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load supplier data')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    await widget.supplierRef.update({
      'name': _supplierNameController.text.trim(),
      'updated_at': DateTime.now(),
    });

    if (mounted) {
      Navigator.pop(context, 'updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Supplier')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _supplierNameController,
                      decoration: const InputDecoration(labelText: 'Nama Supplier'),
                      validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updateSupplier,
                      child: const Text('Update Supplier'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
