import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _photoController = TextEditingController();
  bool _isPromo = false;

  Future<bool> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('http://localhost:8000/api/products'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': _nameController.text,
            'price': int.parse(_priceController.text),
            'photo': _photoController.text,
            'is_promo': _isPromo,
          }),
        );

        final responseData = jsonDecode(response.body);
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product added: ${responseData['product']['name']}')),
          );
          _formKey.currentState!.reset();
          _nameController.clear();
          _priceController.clear();
          _photoController.clear();
          setState(() {
            _isPromo = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${responseData['error'] ?? 'Unknown error'}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Add New Product', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16, width: 10,),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter a product name' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || int.tryParse(value) == null ? 'Enter a valid price' : null,
              ),
              TextFormField(
                controller: _photoController,
                decoration: const InputDecoration(labelText: 'Photo URL'),
                validator: (value) => value == null || value.isEmpty ? 'Enter a photo URL' : null,
              ),
              SwitchListTile(
                title: const Text('Promo'),
                value: _isPromo,
                onChanged: (val) => setState(() => _isPromo = val),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  bool success = await _submitForm();
                  if (success) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Product'),
              ),
            ],
          ),
        )
      ),
    );
  }
}
