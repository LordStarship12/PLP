import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_uts/products/edit_product_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'suppliers/edit_supplier_page.dart';
import 'products/add_product_page.dart';
import 'suppliers/add_supplier_page.dart';
import 'warehouses/add_warehouse_page.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'add_receipt_page.dart';
import 'add_store_page.dart';
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
      theme: ThemeData(
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[900],             
          selectedItemColor: Colors.cyanAccent,     
          unselectedItemColor: Colors.white70,      
          showUnselectedLabels: true,                   
          type: BottomNavigationBarType.fixed,          
        ),
      ),
      debugShowCheckedModeBanner: false,
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
    const SuppliersPage(),
    const WarehousesPage(),
    const ProductsPage(),
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
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Suppliers'),
          BottomNavigationBarItem(icon: Icon(Icons.warehouse), label: 'Warehouses'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Products'),
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
  DocumentReference? _storeRef;
  List<DocumentSnapshot> _allReceipts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReceiptsForStore();
  }

  Future<void> _loadReceiptsForStore() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('store_ref');
    if (storeRefPath == null || storeRefPath.isEmpty) return;

    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);
    final receiptsSnapshot = await FirebaseFirestore.instance
        .collection('purchaseGoodsReceipts')
        .where('store_ref', isEqualTo: storeRef)
        .get();

    List<DocumentSnapshot> allReceipts = [];

    for (var receipt in receiptsSnapshot.docs) {
      allReceipts.add(receipt);
    }

    setState(() {
      _storeRef = storeRef;
      _allReceipts = allReceipts;
      _loading = false;
    });
  }

  Future<List<String>> _resolveReferences(
    DocumentReference? storeRef,
    DocumentReference? supplierRef,
    DocumentReference? warehouseRef,
  ) async {
    final refs = [storeRef, supplierRef, warehouseRef];

    final names = await Future.wait(refs.map((ref) async {
      if (ref == null) return 'Unknown';
      try {
        final doc = await ref.get();
        final data = doc.data() as Map<String, dynamic>?;
        return data?['name']?.toString() ?? 'Unnamed';
      } catch (e) {
        return 'Error';
      }
    }).cast<Future<String>>());

    return names;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt List')),
      body: _loading
          ? const Center(child: Text('Masukkan kode dan nama toko terlebih dahulu.'))
          : _allReceipts.isEmpty
              ? const Center(child: Text('Tidak ada produk.'))
              : ListView.builder(
                  itemCount: _allReceipts.length,
                  itemBuilder: (context, index) {
                    final document = _allReceipts[index];
                    final data = document.data() as Map<String, dynamic>;
                    final postDateRaw = data['post_date'];
                    final postDate = DateTime.tryParse(postDateRaw);
                    final formattedDate = postDate != null
                        ? DateFormat('yyyy-MM-dd').format(postDate)
                        : 'Invalid date';
                    return FutureBuilder<List<String>>(
                      future: _resolveReferences(
                        data['store_ref'],
                        data['supplier_ref'],
                        data['warehouse_ref'],
                      ),
                      builder: (context, snapshot) {
                        final refNames = snapshot.data ?? ['Loading...', 'Loading...', 'Loading...'];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("No. Form: ${data['no_form']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text("Post Date: $formattedDate"),
                                      Text("Grand Total: ${data['grandtotal']}"),
                                      Text("Item Total: ${data['item_total']}"),
                                      Text("Store: ${refNames[0]}"),
                                      Text("Supplier: ${refNames[1]}"),
                                      Text("Warehouse: ${refNames[2]}"),
                                      Text("Synced: ${data['synced'] ? 'Yes' : 'No'}"),
                                      Text("Created At: ${data['created_at'].toDate()}"),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () async {
                                        final result = await showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (_) => EditReceiptModal(
                                            receiptRef: document.reference,
                                            receiptData: data,
                                          ),
                                        );
                                        if (result == 'updated') {
                                          await _loadReceiptsForStore();
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Hapus Receipt?'),
                                            content: const Text('Apakah Anda yakin ingin menghapus receipt ini?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Batal'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('Hapus'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          await document.reference.delete();
                                          await _loadReceiptsForStore();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddStorePage()),
              );
              await _loadReceiptsForStore();
            },
            child: const Text('Pengaturan Toko'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddReceiptPage()),
              );
              await _loadReceiptsForStore();
            },
            child: const Text('Tambah Receipt'),
          ),
        ],
      ),
    );
  }
}

class ReceiptDetailsPage extends StatefulWidget {
  const ReceiptDetailsPage({super.key});

  @override
  State<ReceiptDetailsPage> createState() => _ReceiptDetailsPageState();
}

class _ReceiptDetailsPageState extends State<ReceiptDetailsPage> {
  DocumentReference? _storeRef;
  List<DocumentSnapshot> _allDetails = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetailsForStore();
  }

  Future<void> _loadDetailsForStore() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('store_ref');
    if (storeRefPath == null || storeRefPath.isEmpty) return;

    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);
    final receiptsSnapshot = await FirebaseFirestore.instance
        .collection('purchaseGoodsReceipts')
        .where('store_ref', isEqualTo: storeRef)
        .get();

    List<DocumentSnapshot> allDetails = [];

    for (var receipt in receiptsSnapshot.docs) {
      final detailsSnapshot = await receipt.reference.collection('details').get();
      allDetails.addAll(detailsSnapshot.docs);
    }

    setState(() {
      _storeRef = storeRef;
      _allDetails = allDetails;
      _loading = false;
    });
  }

  Future<String> _resolveReference(DocumentReference? ref) async {
    if (ref == null) return 'Unknown';
    try {
      final doc = await ref.get();
      final data = doc.data() as Map<String, dynamic>?;
      return data?['name']?.toString() ?? 'Unnamed';
    } catch (e) {
      return 'Error';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Details')),
      body: _loading
          ? const Center(child: Text('Masukkan kode dan nama toko terlebih dahulu.'))
          : _allDetails.isEmpty
              ? const Center(child: Text('Tidak ada detail produk.'))
              : ListView.builder(
                  itemCount: _allDetails.length,
                  itemBuilder: (context, index) {
                    final data = _allDetails[index].data() as Map<String, dynamic>;
                    return FutureBuilder<String>(
                      future: _resolveReference(data['product_ref']),
                      builder: (context, snapshot) {
                        final productName = snapshot.data ?? 'Loading...';
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Product: $productName"),
                                Text("Qty: ${data['qty']}"),
                                Text("Unit: ${data['unit_name']}"),
                                Text("Price: ${data['price']}"),
                                Text("Subtotal: ${data['subtotal']}"),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPage();
}

class _SuppliersPage extends State<SuppliersPage> {
  DocumentReference? _storeRef;
  List<DocumentSnapshot> _allSuppliers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliersForStore();
  }

  Future<void> _loadSuppliersForStore() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('store_ref');
    if (storeRefPath == null || storeRefPath.isEmpty) return;

    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);
    final receiptsSnapshot = await FirebaseFirestore.instance
        .collection('suppliers')
        .where('store_ref', isEqualTo: storeRef)
        .get();
    
    List<DocumentSnapshot> allSuppliers= [];

    for (var supplier in receiptsSnapshot.docs) {
      allSuppliers.add(supplier);
    }

    setState(() {
      _storeRef = storeRef;
      _allSuppliers = allSuppliers;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Details')),
      body: _loading
          ? const Center(child: Text('Masukkan kode dan nama toko terlebih dahulu.'))
          : _allSuppliers.isEmpty
              ? const Center(child: Text('Tidak ada detail supplier.'))
              : ListView.builder(
                  itemCount: _allSuppliers.length,
                  itemBuilder: (context, index) {
                    final document = _allSuppliers[index];
                    final data = document.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text("Nama Supplier: ${data['name']}"),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () async {
                                    final result = await showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => EditSupplierModal(
                                        supplierRef: document.reference,
                                      ),
                                    );
                                    if (result == 'updated') {
                                      await _loadSuppliersForStore();
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Hapus Supplier?'),
                                        content: const Text('Apakah Anda yakin ingin menghapus supplier ini?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Batal'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await document.reference.delete();
                                      await _loadSuppliersForStore();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children : [
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddSupplierPage()),
              );
              await _loadSuppliersForStore();
            },
            child: const Text('Tambah Supplier'),
          ),
        ],
      ),
    );
  }
}

class WarehousesPage extends StatefulWidget {
  const WarehousesPage({super.key});

  @override
  State<WarehousesPage> createState() => _WarehousesPage();
}

class _WarehousesPage extends State<WarehousesPage> {
  DocumentReference? _storeRef;
  List<DocumentSnapshot> _allWarehouses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWarehousesForStore();
  }

  Future<void> _loadWarehousesForStore() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('store_ref');
    if (storeRefPath == null || storeRefPath.isEmpty) return;

    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);
    final receiptsSnapshot = await FirebaseFirestore.instance
        .collection('warehouses')
        .where('store_ref', isEqualTo: storeRef)
        .get();
    
    List<DocumentSnapshot> allWarehouses = [];

    for (var warehouse in receiptsSnapshot.docs) {
      allWarehouses.add(warehouse);
    }

    setState(() {
      _storeRef = storeRef;
      _allWarehouses = allWarehouses;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Warehouse Details')),
      body: _loading
          ? const Center(child: Text('Masukkan kode dan nama toko terlebih dahulu.'))
          : _allWarehouses.isEmpty
              ? const Center(child: Text('Tidak ada detail warehouse.'))
              : ListView.builder(
                  itemCount: _allWarehouses.length,
                  itemBuilder: (context, index) {
                    final document = _allWarehouses[index];
                    final data = document.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text("Nama Warehouse: ${data['name']}"),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () async {
                                    final result = await showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => EditSupplierModal(
                                        supplierRef: document.reference,
                                      ),
                                    );
                                    if (result == 'updated') {
                                      await _loadWarehousesForStore();
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Hapus Warehouse?'),
                                        content: const Text('Apakah Anda yakin ingin menghapus warehouse ini?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Batal'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await document.reference.delete();
                                      await _loadWarehousesForStore();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddWarehousePage()),
              );
              await _loadWarehousesForStore();
            },
            child: const Text('Tambah Warehouse'),
          ),
        ],
      ),
    );
  }
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPage();
}

class _ProductsPage extends State<ProductsPage> {
  List<DocumentSnapshot> _allProducts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProductsForStore();
  }

  Future<void> _loadProductsForStore() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('store_ref');
    if (storeRefPath == null || storeRefPath.isEmpty) return;

    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);
    final receiptsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('store_ref', isEqualTo: storeRef)
        .get();
    
    List<DocumentSnapshot> allProducts = [];

    for (var product in receiptsSnapshot.docs) {
      allProducts.add(product);
    }

    setState(() {
      _allProducts = allProducts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: _loading
          ? const Center(child: Text('Masukkan kode dan nama toko terlebih dahulu.'))
          : _allProducts.isEmpty
              ? const Center(child: Text('Tidak ada detail produk.'))
              : ListView.builder(
                  itemCount: _allProducts.length,
                  itemBuilder: (context, index) {
                    final document = _allProducts[index];
                    final data = document.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text("Nama Product: ${data['name']}"),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () async {
                                    final result = await showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => EditProductModal(
                                        productRef: document.reference,
                                      ),
                                    );
                                    if (result == 'updated') {
                                      await _loadProductsForStore();
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Hapus Product?'),
                                        content: const Text('Apakah Anda yakin ingin menghapus product ini?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Batal'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await document.reference.delete();
                                      await _loadProductsForStore();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [       
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddProductPage()),
              );
              await _loadProductsForStore();
            },
            child: const Text('Tambah Product'),
          ),
        ],
      ),
    );
  }
}