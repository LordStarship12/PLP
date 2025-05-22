import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProductModal extends StatefulWidget {
  final DocumentReference productRef;

  const EditProductModal({
    super.key,
    required this.productRef,
  });

  @override
  State<EditProductModal> createState() => _EditProductModalState();
}

class _EditProductModalState extends State<EditProductModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    try {
      final doc = await widget.productRef.get();
      final data = doc.data() as Map<String, dynamic>?;
      _productNameController.text = data?['name'] ?? '';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load product data')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    await widget.productRef.update({
      'name': _productNameController.text.trim(),
      'updated_at': DateTime.now(),
    });

    if (mounted) {
      Navigator.pop(context, 'updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _productNameController,
                      decoration: const InputDecoration(labelText: 'Nama Product'),
                      validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updateProduct,
                      child: const Text('Update Product'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
