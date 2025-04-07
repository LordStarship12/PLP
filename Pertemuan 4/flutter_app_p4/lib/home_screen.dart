import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (products.isEmpty) {
      return const Center(child: Text('There are no products available.'));
    } 

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isPromo = product['is_promo'] == true ? 'Ada' : 'Tidak';

        return ListTile(
          title: Text(product['name']),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Harga: Rp${product['price']}'),
              Image.network(product['photo']),
              Text('Promo: $isPromo'),
            ],
          ),
        );
      },
    );
  }
}