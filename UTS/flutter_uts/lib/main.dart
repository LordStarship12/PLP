import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'add_receipt_page.dart';
import 'add_store_page.dart';
import 'add_detail_page.dart';
import 'edit_receipt_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "UAS PALP 2025 - Timothy Valentivo",
      theme: ThemeData(primarySwatch: Colors.lightBlue),
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const ReceiptListPage(),
    const ReceiptDetailsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Receipts'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Details'),
        ],
      ),
    );
  }
}

class ReceiptListPage extends StatefulWidget {
  const ReceiptListPage({super.key});

  @override
  State<ReceiptListPage> createState() => _ReceiptListPageState();
}

class _ReceiptListPageState extends State<ReceiptListPage> {
  final CollectionReference receipts = FirebaseFirestore.instance.collection('purchaseGoodsReceipts');
  DocumentReference? _storeRef;
  Stream<QuerySnapshot>? _receiptStream;

  @override
  void initState() {
    super.initState();
    _loadStoreRef();
  }

  Future<void> _loadStoreRef() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('store_ref');
    if (storeRefPath != null && storeRefPath.isNotEmpty) {
      final storeRef = FirebaseFirestore.instance.doc(storeRefPath);
      setState(() {
        _storeRef = storeRef;
        _receiptStream = receipts
            .where('store_ref', isEqualTo: storeRef)
            .orderBy('created_at', descending: true)
            .snapshots();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt List')),
      body: _storeRef == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _receiptStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Tidak ada produk.'));
                }
                return ListView(
                  children: snapshot.data!.docs.map((DocumentSnapshot document) {
                    final data = document.data()! as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => EditReceiptModal(document: document),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("No. Form: ${data['no_form']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("Post Date: ${data['post_date']}"),
                              Text("Grand Total: ${data['grandtotal']}"),
                              Text("Item Total: ${data['item_total']}"),
                              Text("Store: ${data['store_ref'].path}"),
                              Text("Supplier: ${data['supplier_ref'].path}"),
                              Text("Warehouse: ${data['warehouse_ref'].path}"),
                              Text("Synced: ${data['synced'] ? 'Yes' : 'No'}"),
                              Text("Created At: ${data['created_at'].toDate()}"),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddStorePage()));
            },
            child: const Text('Tambah Nama Toko'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddReceiptPage()));
            },
            child: const Text('Tambah Receipt'),
          ),
        ],
      ),
    );
  }
}

class ReceiptDetailsPage extends StatelessWidget {
  const ReceiptDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final detailsCollection = FirebaseFirestore.instance.collectionGroup('details');

    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Details')),
      body: StreamBuilder<QuerySnapshot>(
        stream: detailsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Tidak ada detail produk.'));
          }
          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              final data = document.data()! as Map<String, dynamic>;
              return 
              GestureDetector(
                onTap: () 
                {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => EditReceiptModal(document: document),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Product Ref: ${data['product_ref'].path}"),
                        Text("Qty: ${data['qty']}"),
                        Text("Unit: ${data['unit_name']}"),
                        Text("Price: ${data['price']}"),
                        Text("Subtotal: ${data['subtotal']}"),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddDetailPage()));
            },
            child: const Text('Tambah Produk'),
          ),
        ],
      ),
    );
  }
}
