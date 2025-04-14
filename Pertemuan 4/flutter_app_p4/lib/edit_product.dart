import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProductForm extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onSuccess;

  const EditProductForm({super.key, required this.product, required this.onSuccess});

  @override
  State<EditProductForm> createState() => _EditProductFormState();
}

class _EditProductFormState extends State<EditProductForm> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _photoController;
  late bool _isPromo;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product['name']);
    _priceController = TextEditingController(text: widget.product['price'].toString());
    _photoController = TextEditingController(text: widget.product['photo']);
    _isPromo = widget.product['is_promo'] == true;
  }

  Future<void> _submitEdit() async {
    final response = await http.put(
      Uri.parse('http://localhost:8000/api/products/${widget.product['id']}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': _nameController.text,
        'price': int.tryParse(_priceController.text),
        'photo': _photoController.text,
        'is_promo': _isPromo,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product updated successfully")),
      );
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update product")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material( // Required to avoid 'No Material widget' error
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text('Edit Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Image.network(widget.product['photo'], height: 120),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _photoController,
              decoration: const InputDecoration(labelText: 'Photo URL'),
            ),
            SwitchListTile(
              title: const Text('Promo'),
              value: _isPromo,
              onChanged: (val) => setState(() => _isPromo = val),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitEdit,
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

