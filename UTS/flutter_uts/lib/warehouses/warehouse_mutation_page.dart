import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WarehouseMutationPage extends StatefulWidget {
  const WarehouseMutationPage({super.key});

  @override
  State<WarehouseMutationPage> createState() => _WarehouseMutationPageState();
}

class _WarehouseMutationPageState extends State<WarehouseMutationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController quantityController = TextEditingController();

  List<DocumentSnapshot> _warehouses = [];
  List<DocumentSnapshot> _products = [];

  DocumentReference? selectedItem;
  DocumentReference? fromWarehouse;
  DocumentReference? toWarehouse;

  bool _submitting = false;

  final Color pastelBlue = const Color(0xFFE3F2FD);
  final Color primaryBlue = const Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('customer_ref');
    if (storeRefPath == null) return;
    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);

    final warehouses = await FirebaseFirestore.instance
        .collection('warehouses')
        .where('customer_ref', isEqualTo: storeRef)
        .get();

    final products = await FirebaseFirestore.instance
        .collection('products')
        .where('customer_ref', isEqualTo: storeRef)
        .get();

    setState(() {
      _warehouses = warehouses.docs;
      _products = products.docs;
    });
  }

  Future<void> submitMutation() async {
    if (!_formKey.currentState!.validate() ||
        selectedItem == null ||
        fromWarehouse == null ||
        toWarehouse == null) {
      return;
    }

    if (fromWarehouse == toWarehouse) {
      _showSnackBar('Gudang asal dan tujuan tidak boleh sama');
      return;
    }

    final qty = int.tryParse(quantityController.text);
    if (qty == null || qty <= 0) {
      _showSnackBar('Jumlah tidak valid');
      return;
    }

    setState(() => _submitting = true);

    try {
      final firestore = FirebaseFirestore.instance;

      final fromStockQuery = await firestore
          .collection('stocks')
          .where('product_ref', isEqualTo: selectedItem)
          .where('warehouse_ref', isEqualTo: fromWarehouse)
          .limit(1)
          .get();

      if (fromStockQuery.docs.isEmpty) {
        throw Exception('Stok tidak ditemukan di gudang asal');
      }

      final fromStockDoc = fromStockQuery.docs.first;
      final currentFromQty = fromStockDoc['qty'] ?? 0;

      if (currentFromQty < qty) {
        throw Exception('Jumlah melebihi stok tersedia ($currentFromQty)');
      }

      final toStockQuery = await firestore
          .collection('stocks')
          .where('product_ref', isEqualTo: selectedItem)
          .where('warehouse_ref', isEqualTo: toWarehouse)
          .limit(1)
          .get();

      final toStockExists = toStockQuery.docs.isNotEmpty;
      final toStockDoc = toStockExists ? toStockQuery.docs.first : null;

      await firestore.runTransaction((transaction) async {
        final newFromQty = currentFromQty - qty;

        if (newFromQty == 0) {
          transaction.delete(fromStockDoc.reference);
        } else {
          transaction.update(fromStockDoc.reference, {'qty': newFromQty});
        }

        if (toStockExists) {
          final currentToQty = toStockDoc!['qty'] ?? 0;
          transaction.update(toStockDoc.reference, {'qty': currentToQty + qty});
        } else {
          final newStockRef = firestore.collection('stocks').doc();
          transaction.set(newStockRef, {
            'product_ref': selectedItem,
            'warehouse_ref': toWarehouse,
            'qty': qty,
          });
        }
      });

      if (mounted) {
        Navigator.pop(context, 'mutated');
      }
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelBlue,
      appBar: AppBar(title: const Text('Mutasi Barang')),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<DocumentReference>(
                value: selectedItem,
                icon: const SizedBox.shrink(),
                items: _products.map((doc) {
                  return DropdownMenuItem(
                    value: doc.reference,
                    child: Text(doc['name']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedItem = value),
                decoration: const InputDecoration(
                  labelText: "Barang",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null ? 'Pilih barang' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DocumentReference>(
                value: fromWarehouse,
                icon: const SizedBox.shrink(),
                items: _warehouses.map((doc) {
                  return DropdownMenuItem(
                    value: doc.reference,
                    child: Text(doc['name']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => fromWarehouse = value),
                decoration: const InputDecoration(
                  labelText: "Gudang Asal",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null ? 'Pilih gudang asal' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DocumentReference>(
                value: toWarehouse,
                icon: const SizedBox.shrink(),
                items: _warehouses.map((doc) {
                  return DropdownMenuItem(
                    value: doc.reference,
                    child: Text(doc['name']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => toWarehouse = value),
                decoration: const InputDecoration(
                  labelText: "Gudang Tujuan",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null ? 'Pilih gudang tujuan' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final qty = int.tryParse(value ?? '');
                  if (qty == null || qty <= 0) return 'Jumlah harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : submitMutation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Kirim Mutasi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
