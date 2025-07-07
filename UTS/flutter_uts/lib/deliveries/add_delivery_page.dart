  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:intl/intl.dart';

  class AddDeliveryPage extends StatefulWidget {
    const AddDeliveryPage({super.key});

    @override
    State<AddDeliveryPage> createState() => _AddDeliveryPageState();
  }

  class _AddDeliveryPageState extends State<AddDeliveryPage> {
    final NumberFormat fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final TextEditingController descCtrl = TextEditingController();
    DateTime postDate = DateTime.now();
    String invoiceNo = '';
    DocumentReference? customerStoreRef, warehouseRef, salesmanRef;

    List<DocumentSnapshot> stores = [], warehouses = [], salesmen = [];
    List<DocumentSnapshot> stockDocs = []; // Stocks tied to selected warehouse
    List<_Item> items = [];

    final Color pastelBlue = const Color(0xFFE3F2FD);
    final Color primaryBlue = const Color(0xFF2196F3);

    int get itemCount => items.fold(0, (sum, i) => sum + i.qty);
    int get totalAmt => items.fold(0, (sum, i) => sum + i.subtotal);

    @override
    void initState() {
      super.initState();
      _loadInitialData();
      _generateInvoiceNumber();
    }

    Future<void> _loadInitialData() async {
      final prefs = await SharedPreferences.getInstance();
      final storePath = prefs.getString('customer_ref');
      if (storePath == null) return;
      final storeRef = FirebaseFirestore.instance.doc(storePath);

      final s = await FirebaseFirestore.instance
          .collection('customers')
          .where('customer_ref', isEqualTo: storeRef)
          .get();
      final w = await FirebaseFirestore.instance
          .collection('warehouses')
          .where('customer_ref', isEqualTo: storeRef)
          .get();
      final sm = await FirebaseFirestore.instance
          .collection('salesmen')
          .where('customer_ref', isEqualTo: storeRef)
          .get();

      setState(() {
        stores = s.docs..removeWhere((doc) => doc.reference.path == storePath);
        warehouses = w.docs;
        salesmen = sm.docs;
      });
    }

    Future<void> _generateInvoiceNumber() async {
      final col = await FirebaseFirestore.instance
          .collection('deliveries')
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();
      final base = 'TTJ22100034';
      int max = 0;

      if (col.docs.isNotEmpty) {
        final parts = (col.docs.first['no_faktur'] as String).split('_');
        if (parts.length == 2) {
          max = int.tryParse(parts[1]) ?? 0;
        }
      }

      setState(() {
        invoiceNo = '${base}_${max + 1}';
      });
    }

    Future<void> _loadStocksForWarehouse(DocumentReference warehouse) async {
      final result = await FirebaseFirestore.instance
          .collection('stocks')
          .where('warehouse_ref', isEqualTo: warehouse)
          .get();

      setState(() {
        stockDocs = result.docs;
        items.clear(); // clear all items when warehouse changes
      });
    }

    void _addItem() {
      if (warehouseRef == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih gudang terlebih dahulu.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        items.add(_Item(stockDocs: stockDocs));
      });
    }

    void _removeItem(int index) => setState(() => items.removeAt(index));

    Future<void> _submit() async {
      if (customerStoreRef == null ||
          warehouseRef == null ||
          salesmanRef == null ||
          items.any((i) => i.productRef == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lengkapi semua data terlebih dahulu.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final storeRefPath = prefs.getString('customer_ref');
      final storeRef = FirebaseFirestore.instance.doc(storeRefPath!);

      final delivery = {
        'no_faktur': invoiceNo,
        'customer_ref': storeRef,
        'customer_store_ref': customerStoreRef,
        'warehouse_ref': warehouseRef,
        'salesman_ref': salesmanRef,
        'description': descCtrl.text.trim(),
        'post_date': postDate.toIso8601String(),
        'item_total': itemCount,
        'grandtotal': totalAmt,
        'created_at': DateTime.now(),
        'synced': true,
      };

      final deliveryDoc = await FirebaseFirestore.instance.collection('deliveries').add(delivery);

      for (final item in items) {
        await deliveryDoc.collection('details').add(item.toMap());

        // Update stock
        final stock = stockDocs.firstWhere((s) => s['product_ref'] == item.productRef);
        final stockRef = stock.reference;
        final currentQty = stock['qty'];
        final newQty = currentQty - item.qty;

        if (newQty <= 0) {
          await stockRef.delete();
        } else {
          await stockRef.update({'qty': newQty});
        }

        // Update product stock too
        final productSnap = await item.productRef!.get();
        final prodQty = productSnap['qty'] ?? 0;
        await item.productRef!.update({'qty': prodQty - item.qty});
      }

      if (mounted) Navigator.pop(context, 'saved');
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: pastelBlue,
        appBar: AppBar(title: const Text('Tambah Faktur')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(children: [
            Text('No. Faktur: $invoiceNo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButton<DocumentReference>(
                  value: customerStoreRef,
                  icon: const SizedBox.shrink(),
                  hint: const Text('Pilih Customer'),
                  items: stores.map((d) => DropdownMenuItem(value: d.reference, child: Text(d['name']))).toList(),
                  onChanged: (v) => setState(() => customerStoreRef = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<DocumentReference>(
                  value: salesmanRef,
                  icon: const SizedBox.shrink(),
                  hint: const Text('Pilih Salesman'),
                  items: salesmen.map((d) => DropdownMenuItem(value: d.reference, child: Text(d['name']))).toList(),
                  onChanged: (v) => setState(() => salesmanRef = v),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButton<DocumentReference>(
                  value: warehouseRef,
                  icon: const SizedBox.shrink(),
                  hint: const Text('Pilih Gudang'),
                  items: warehouses.map((d) => DropdownMenuItem(value: d.reference, child: Text(d['name']))).toList(),
                  onChanged: (v) async {
                    if (v != null) {
                      warehouseRef = v;
                      await _loadStocksForWarehouse(v);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: postDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => postDate = picked);
                },
                child: Text(DateFormat('yyyy-MM-dd').format(postDate)),
              ),
            ]),
            const Divider(height: 24),
            const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...items.asMap().entries.map((e) {
              final i = e.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: DropdownButton<DocumentReference>(
                          value: i.productRef,
                          icon: const SizedBox.shrink(),
                          hint: const Text('Produk'),
                          items: stockDocs.map((s) {
                            final prodRef = s['product_ref'] as DocumentReference;
                            return DropdownMenuItem(
                              value: prodRef,
                              child: FutureBuilder<DocumentSnapshot>(
                                future: prodRef.get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState != ConnectionState.done) {
                                    return const Text("Loading...");
                                  }
                                  if (!snapshot.hasData || !snapshot.data!.exists) {
                                    return const Text("Unknown Product");
                                  }
                                  final productName = snapshot.data!['name'] ?? prodRef.id;
                                  return Text(productName);
                                },
                              ),
                            );
                          }).toList(),
                          onChanged: (v) async {
                            i.productRef = v;
                            final productSnap = await v!.get();
                            final price = productSnap['default_price'] ?? 0;
                            setState(() => i.price = price);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeItem(e.key),
                      ),
                    ]),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: i.qty.toString(),
                          decoration: const InputDecoration(labelText: 'Qty'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final val = int.tryParse(v) ?? 1;
                            final stock = i.getAvailableStock();
                            if (val <= stock) {
                              setState(() => i.qty = val);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Qty melebihi stok ($stock tersedia)'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: i.price.toString(),
                          decoration: const InputDecoration(labelText: 'Harga'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() => i.price = int.tryParse(v) ?? 0),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text('Subtotal: ${fmt.format(i.subtotal)}', style: const TextStyle(fontSize: 16)),
                  ]),
                ),
              );
            }),
            TextButton.icon(
              icon: const Icon(Icons.add, color: Colors.black54),
              label: const Text('Tambah Item', style: TextStyle(color: Colors.black87)),
              onPressed: _addItem,
            ),
            const Divider(height: 24),
            Text('Total Items: $itemCount'),
            Text('Total Bayar: ${fmt.format(totalAmt)}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: primaryBlue, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _submit,
              child: const Text('Simpan Faktur', style: TextStyle(fontSize: 16)),
            ),
          ]),
        ),
      );
    }
  }

  class _Item {
    DocumentReference? productRef;
    int qty = 1, price = 0;
    final List<DocumentSnapshot> stockDocs;

    _Item({required this.stockDocs});

    int get subtotal => qty * price;

    int getAvailableStock() {
      try {
        final stockDoc = stockDocs.firstWhere((s) => s['product_ref'] == productRef);
        return stockDoc['qty'] ?? 0;
      } catch (_) {
        return 0;
      }
    }

    Map<String, dynamic> toMap() => {
          'product_ref': productRef,
          'qty': qty,
          'price': price,
          'unit_name': 'pcs',
          'subtotal': subtotal,
        };
  }
