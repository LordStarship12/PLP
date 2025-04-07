import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  List products = [];
  Map<String, dynamic>? selectedProduct;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _photoController = TextEditingController();
  bool _isPromo = false;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final response = await http.get(Uri.parse('http://localhost:8000/api/products'));
    if (response.statusCode == 200) {
      setState(() {
        products = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load products');
    }
  }

  void fillForm(Map<String, dynamic> product) {
    setState(() {
      selectedProduct = product;
      _nameController.text = product['name'];
      _priceController.text = product['price'].toString();
      _photoController.text = product['photo'];
      _isPromo = product['is_promo'] ?? false;
    });
  }

  Future<void> _submitEdit() async {
    if (_formKey.currentState!.validate() && selectedProduct != null) {
      final response = await http.put(
        Uri.parse('http://localhost:8000/api/products/${selectedProduct!['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'price': int.parse(_priceController.text),
          'photo': _photoController.text,
          'is_promo': _isPromo,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully!')),
        );
        setState(() {
          selectedProduct = null;
        });
        await fetchProducts(); // refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update product')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return selectedProduct == null
        ? ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product['name']),
                onTap: () => fillForm(product),
              );
            },
          )
        : Center(
            child: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text('Edit Product', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Product Name'),
                        validator: (value) => value == null || value.isEmpty ? 'Enter product name' : null,
                      ),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || int.tryParse(value) == null ? 'Enter valid price' : null,
                      ),
                      TextFormField(
                        controller: _photoController,
                        decoration: const InputDecoration(labelText: 'Photo URL'),
                        validator: (value) => value == null || value.isEmpty ? 'Enter photo URL' : null,
                      ),
                      const SizedBox(height: 10),
                      Image.network(_photoController.text, height: 150, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                      SwitchListTile(
                        title: const Text('Promo'),
                        value: _isPromo,
                        onChanged: (val) => setState(() => _isPromo = val),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await _submitEdit();
                        },
                        child: const Text('Submit Edit'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => selectedProduct = null),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
