import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'edit_product.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List products = [];
  bool isLoading = true;

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/api/products'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          products = decoded is List ? decoded : decoded['data']; 
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      final response = await http.delete(Uri.parse('http://localhost:8000/api/products/$id'));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
        fetchProducts(); // Refresh list
      } else {
        throw Exception('Failed to delete');
      }
    } catch (e) {
      print('Delete error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  void showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteProduct(id);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void showEditModal(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: EditProductForm(
          product: product,
          onSuccess: () {
            Navigator.pop(context); // Close the modal
            fetchProducts();        // Refresh list
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : products.isEmpty
            ? const Center(child: Text("There's no product available"))
            : ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    title: Text(product['name']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => showEditModal(product),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => showDeleteConfirmation(product['id']),
                        ),
                      ],
                    ),
                  );
                },
              );
  }
}
