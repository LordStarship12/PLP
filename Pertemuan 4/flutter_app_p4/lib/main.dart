import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Produk API Demo',
      home: ProductListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List products = [];
  bool isLoading = true;

  final String apiUrl = 'http://localhost:8000/api/products';

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data');
      }
    } catch (e) {
      print ('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Produk')),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            String isPromo;   

            if(product['is_promo'] == true) {
              isPromo = 'Ada';
            } else {
              isPromo = 'Tidak';
            }

            return ListTile(
              title: Text(product['name']),
              subtitle: Column(
                children: [
                  Text('Harga: Rp${product['price']}'),
                  Image.network(product['photo']),
                  Text('Apakah ada promo: $isPromo'),
                ]
              )
            );
          },
        ),
    );
  }
}
