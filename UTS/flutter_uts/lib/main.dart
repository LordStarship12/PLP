import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:bcrypt/bcrypt.dart';

import 'deliveries/add_delivery_page.dart';
import 'deliveries/edit_delivery_page.dart';
import 'customers/add_customer_page.dart';
import 'customers/edit_customer_page.dart';
import 'products/add_product_page.dart';
import 'products/edit_product_page.dart';
import 'receipts/add_receipt_page.dart';
import 'receipts/edit_receipt_page.dart';
import 'salesmen/add_salesman_page.dart';
import 'salesmen/edit_salesman_page.dart';
import 'suppliers/add_supplier_page.dart';
import 'suppliers/edit_supplier_page.dart';
import 'warehouses/add_warehouse_page.dart';
import 'warehouses/edit_warehouse_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final storeRef = prefs.getString('customer_ref');
  print(storeRef);

  runApp(MainApp(storeRef: storeRef));
}

class MainApp extends StatelessWidget {
  final String? storeRef;
  const MainApp({super.key, this.storeRef});

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
      home: storeRef == null ? const LoginPage() : const MainScaffold(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _error = "Username tidak ditemukan.";
          _loading = false;
        });
        return;
      }

      final customerDoc = snapshot.docs.first;
      final data = customerDoc.data();
      final hashedPassword = data['password'];

      if (!BCrypt.checkpw(password, hashedPassword)) {
        setState(() {
          _error = "Password salah.";
          _loading = false;
        });
        return;
      }

      final customerId = customerDoc.id;
      final storeRef = FirebaseFirestore.instance.doc('customers/$customerId');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customer_ref', storeRef.path);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScaffold()),
      );
    } catch (e) {
      print(e);
      setState(() {
        _error = "Terjadi kesalahan saat login.";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFf8e8ee),
              Color(0xFFe0f7fa),
              Color(0xFFf3f1ff),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Color(0xF2FFFFFF) ,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Welcome Back 👋',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please login to continue',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: 'Username',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: const Color(0xFF80DEEA),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ReceiptListPage(),
    const DeliveryListPage(),
    const CustomersPage(),
    const SalesmenPage(),
    const SuppliersPage(),
    const WarehousesPage(),
    const ProductsPage(),
  ];

  final List<String> _titles = [
    'Receipts',
    'Sales Invoices',
    'Customers',
    'Salesmen',
    'Suppliers',
    'Warehouses',
    'Products',
  ];

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.cyan),
              child: Text('UAS PALP 2025', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Receipts'),
              onTap: () => _onDrawerItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Sales Invoices'),
              onTap: () => _onDrawerItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.store_outlined),
              title: const Text('Customers'),
              onTap: () => _onDrawerItemTapped(2),
            ),
            ListTile(
              leading: const Icon(Icons.man),
              title: const Text('Salesmen'),
              onTap: () => _onDrawerItemTapped(3),
            ),  
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Suppliers'),
              onTap: () => _onDrawerItemTapped(4),
            ),
            ListTile(
              leading: const Icon(Icons.warehouse),
              title: const Text('Warehouses'),
              onTap: () => _onDrawerItemTapped(5),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Products'),
              onTap: () => _onDrawerItemTapped(6),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('customer_ref');

                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

class ReceiptListPage extends StatefulWidget {
  const ReceiptListPage({super.key});

  @override
  State<ReceiptListPage> createState() => _ReceiptListPageState();
}

class _ReceiptListPageState extends State<ReceiptListPage> {
  List<DocumentSnapshot> _allReceipts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReceiptsForStore();
  }

  Future<void> _loadReceiptsForStore() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('customer_ref');
    if (storeRefPath == null || storeRefPath.isEmpty) return;

    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);
    final receiptsSnapshot = await FirebaseFirestore.instance
        .collection('purchaseGoodsReceipts')
        .where('customer_ref', isEqualTo: storeRef)
        .get();

    setState(() {
      _allReceipts = receiptsSnapshot.docs;
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

  Future<String> _resolveProductName(DocumentReference? ref) async {
    if (ref == null) return 'Unknown';
    try {
      final doc = await ref.get();
      final data = doc.data() as Map<String, dynamic>?;
      return data?['name'] ?? 'Unnamed';
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allReceipts.isEmpty
              ? const Center(child: Text('Tidak ada produk.'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(12.0),
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: IntrinsicWidth(
                          child: DataTable(
                            headingRowHeight: 48,
                            columnSpacing: 24,
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            columns: const [
                              DataColumn(label: Text('No. Form', textAlign: TextAlign.center)),
                              DataColumn(label: Text('Tanggal', textAlign: TextAlign.center)),
                              DataColumn(label: Text('Grand Total', textAlign: TextAlign.center)),
                              DataColumn(label: Text('Qty Total', textAlign: TextAlign.center)),
                              DataColumn(label: Text('Store', textAlign: TextAlign.center)),
                              DataColumn(label: Text('Supplier', textAlign: TextAlign.center)),
                              DataColumn(label: Text('Warehouse', textAlign: TextAlign.center)),
                              DataColumn(label: Text('Aksi', textAlign: TextAlign.center)),
                              DataColumn(label: Text('Detail Produk', textAlign: TextAlign.center)),
                            ],
                            rows: _allReceipts.map((document) {
                              final data = document.data() as Map<String, dynamic>;
                              final postDate = DateTime.tryParse(data['post_date'] ?? '') ?? (data['created_at'] as Timestamp).toDate();
                              Widget centeredCell(String text) => Center(child: Text(text, textAlign: TextAlign.center));
                              return DataRow(
                                cells: [
                                  DataCell(centeredCell(data['no_form'] ?? '')),
                                  DataCell(centeredCell(DateFormat('yyyy-MM-dd').format(postDate))),
                                  DataCell(centeredCell(rupiahFormat.format(data['grandtotal']))),
                                  DataCell(centeredCell('${data['item_total']}')),
                                  DataCell(
                                    Center(
                                      child: FutureBuilder<List<String>>(
                                        future: _resolveReferences(
                                          data['customer_ref'],
                                          data['supplier_ref'],
                                          data['warehouse_ref'],
                                        ),
                                        builder: (context, snapshot) {
                                          final refNames = snapshot.data ?? ['...', '...', '...'];
                                          return Text(refNames[0], textAlign: TextAlign.center);
                                        },
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: FutureBuilder<List<String>>(
                                        future: _resolveReferences(
                                          data['customer_ref'],
                                          data['supplier_ref'],
                                          data['warehouse_ref'],
                                        ),
                                        builder: (context, snapshot) {
                                          final refNames = snapshot.data ?? ['...', '...', '...'];
                                          return Text(refNames[1], textAlign: TextAlign.center);
                                        },
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: FutureBuilder<List<String>>(
                                        future: _resolveReferences(
                                          data['customer_ref'],
                                          data['supplier_ref'],
                                          data['warehouse_ref'],
                                        ),
                                        builder: (context, snapshot) {
                                          final refNames = snapshot.data ?? ['...', '...', '...'];
                                          return Text(refNames[2], textAlign: TextAlign.center);
                                        },
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
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
                                                final detailsSnapshot = await document.reference.collection('details').get();
                                                for (var detailDoc in detailsSnapshot.docs) {
                                                  final detailData = detailDoc.data();
                                                  final productRef = detailData['product_ref'] as DocumentReference?;
                                                  final warehouseRef = detailData['warehouse_ref'] as DocumentReference? ?? data['warehouse_ref'];
                                                  final qty = detailData['qty'];
                                                  if (productRef != null && warehouseRef != null && qty != null) {
                                                    final stockQuery = await FirebaseFirestore.instance
                                                        .collection('stocks')
                                                        .where('product_ref', isEqualTo: productRef)
                                                        .where('warehouse_ref', isEqualTo: warehouseRef)
                                                        .limit(1)
                                                        .get();
                                                    if (stockQuery.docs.isNotEmpty) {
                                                      final stockDoc = stockQuery.docs.first;
                                                      final stockRef = stockDoc.reference;
                                                      final stockData = stockDoc.data();
                                                      final stockQty = stockData['qty'] ?? 0;
                                                      if (stockQty == qty) {
                                                        await stockRef.delete();
                                                      } else if (stockQty > qty) {
                                                        await stockRef.update({'qty': stockQty - qty});
                                                      }
                                                    }
                                                    await FirebaseFirestore.instance.runTransaction((transaction) async {
                                                      final productSnap = await transaction.get(productRef);
                                                      final productData = productSnap.data() as Map<String, dynamic>?;
                                                      final currentQty = productData?['qty'] ?? 0;
                                                      transaction.update(productRef, {
                                                        'qty': currentQty - qty,
                                                      });
                                                    });
                                                  }
                                                  await detailDoc.reference.delete();
                                                }
                                                await document.reference.delete();
                                                await _loadReceiptsForStore();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final detailSnapshot = await document.reference.collection('details').get();
                                          final detailDocs = detailSnapshot.docs;
                                          showDialog(
                                            context: context,
                                            builder: (context) => Dialog(
                                              child: Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                                    children: detailDocs.map((doc) {
                                                      final detail = doc.data();
                                                      return FutureBuilder<String>(
                                                        future: _resolveProductName(detail['product_ref']),
                                                        builder: (context, snapshot) {
                                                          final productName = snapshot.data ?? 'Loading...';
                                                          return Card(
                                                            margin: const EdgeInsets.symmetric(vertical: 8),
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(12),
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                                  Text("Qty: ${detail['qty']} ${detail['unit_name']}"),
                                                                  Text("Price: ${rupiahFormat.format(detail['price'])}"),
                                                                  Text("Subtotal: ${rupiahFormat.format(detail['subtotal'])}"),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text("Lihat Detail"),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddReceiptPage()),
          );
          await _loadReceiptsForStore();
        },
        tooltip: 'Tambah Receipt',
        backgroundColor: Colors.green,
        elevation: 6,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}                          

class DeliveryListPage extends StatefulWidget {
  const DeliveryListPage({super.key});

  @override
  State<DeliveryListPage> createState() => _DeliveryListPageState();
}

class _DeliveryListPageState extends State<DeliveryListPage> {
  List<DocumentSnapshot> _allInvoices = [];
  bool _loading = true;

  final rupiahFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('customer_ref');
    if (storeRefPath == null || storeRefPath.isEmpty) return;

    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);
    final invoicesSnapshot = await FirebaseFirestore.instance
        .collection('deliveries')
        .where('customer_ref', isEqualTo: storeRef)
        .get();

    setState(() {
      _allInvoices = invoicesSnapshot.docs;
      _loading = false;
    });
  }

  Future<List<String>> _resolveReferences(
    DocumentReference? storeRef,
    DocumentReference? warehouseRef,
    DocumentReference? salesmanRef,
  ) async {
    final refs = [storeRef, warehouseRef, salesmanRef];
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


  Future<String> _resolveProductName(DocumentReference? ref) async {
    if (ref == null) return 'Unknown';
    try {
      final doc = await ref.get();
      final data = doc.data() as Map<String, dynamic>?;
      return data?['name'] ?? 'Unnamed';
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
    ? const Center(child: CircularProgressIndicator())
    : _allInvoices.isEmpty
        ? const Center(child: Text('Tidak ada sales invoice.'))
        : LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: IntrinsicWidth(
                    child: DataTable(
                      headingRowHeight: 48,
                      columnSpacing: 24,
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      columns: const [
                        DataColumn(label: Center(child: Text('No. Faktur'))),
                        DataColumn(label: Center(child: Text('Tanggal'))),
                        DataColumn(label: Center(child: Text('Grand Total'))),
                        DataColumn(label: Center(child: Text('Item Total'))),
                        DataColumn(label: Center(child: Text('Customer'))),
                        DataColumn(label: Center(child: Text('Warehouse'))),
                        DataColumn(label: Center(child: Text('Salesman'))),
                        DataColumn(label: Center(child: Text('Deskripsi'))),
                        DataColumn(label: Center(child: Text('Aksi'))),
                      ],
                      rows: _allInvoices.map((document) {
                        final data = document.data() as Map<String, dynamic>;
                        final postDate = DateTime.tryParse(data['post_date'] ?? '') ?? (data['created_at'] as Timestamp).toDate();
                        Widget centeredCell(String text) => Center(child: Text(text, textAlign: TextAlign.center));

                        return DataRow(
                          cells: [
                            DataCell(centeredCell(data['no_faktur'] ?? '')),
                            DataCell(centeredCell(DateFormat('yyyy-MM-dd').format(postDate))),
                            DataCell(centeredCell(rupiahFormat.format(data['grandtotal']))),
                            DataCell(centeredCell('${data['item_total']}')),
                            DataCell(
                              Center(
                                child: FutureBuilder<List<String>>(
                                  future: _resolveReferences(
                                    data['customer_store_ref'],
                                    data['warehouse_ref'],
                                    data['salesman_ref']
                                  ),
                                  builder: (context, snapshot) {
                                    final names = snapshot.data ?? ['...', '...'];
                                    return Text(names[0], textAlign: TextAlign.center);
                                  },
                                ),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: FutureBuilder<List<String>>(
                                  future: _resolveReferences(
                                    data['customer_store_ref'],
                                    data['warehouse_ref'],
                                    data['salesman_ref'],
                                  ),
                                  builder: (context, snapshot) {
                                    final names = snapshot.data ?? ['...', '...'];
                                    return Text(names[1], textAlign: TextAlign.center);
                                  },
                                ),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: FutureBuilder<List<String>>(
                                  future: _resolveReferences(
                                    data['customer_store_ref'],
                                    data['warehouse_ref'],
                                    data['salesman_ref'],
                                  ),
                                  builder: (context, snapshot) {
                                    final names = snapshot.data ?? ['...', '...'];
                                    return Text(names[2], textAlign: TextAlign.center);
                                  },
                                ),
                              ),
                            ),
                            DataCell(centeredCell(data['description'] ?? '')),
                            DataCell(
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        final detailSnapshot = await document.reference.collection('details').get();
                                        final detailDocs = detailSnapshot.docs;
                                        final refNames = await _resolveReferences(
                                          data['customer_store_ref'],
                                          data['warehouse_ref'],
                                          data['salesman_ref'],
                                        );
                                    
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => POSInvoiceView(
                                              invoiceData: data,
                                              detailDocs: detailDocs,
                                              refNames: refNames,
                                              rupiahFormat: rupiahFormat,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('Lihat POS'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () async {
                                        final result = await showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (_) => EditDeliveryModal(
                                            invoiceRef: document.reference,
                                            invoiceData: data,
                                          ),
                                        );
                                        if (result == 'updated') {
                                          await _loadInvoices();
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Hapus Sales Invoice?'),
                                            content: const Text('Apakah Anda yakin ingin menghapus sales invoice ini?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          final detailsSnapshot = await document.reference.collection('details').get();
                                          for (var detailDoc in detailsSnapshot.docs) {
                                            final detailData = detailDoc.data();
                                            final productRef = detailData['product_ref'] as DocumentReference?;
                                            final warehouseRef = data['warehouse_ref'];
                                            final qty = detailData['qty'];
                                            if (productRef != null && warehouseRef != null && qty != null) {
                                              final stockQuery = await FirebaseFirestore.instance
                                                  .collection('stocks')
                                                  .where('product_ref', isEqualTo: productRef)
                                                  .where('warehouse_ref', isEqualTo: warehouseRef)
                                                  .limit(1)
                                                  .get();
                                              if (stockQuery.docs.isNotEmpty) {
                                                final stockDoc = stockQuery.docs.first;
                                                final stockRef = stockDoc.reference;
                                                final stockData = stockDoc.data();
                                                final stockQty = stockData['qty'] ?? 0;
                                                await stockRef.update({'qty': stockQty + qty});
                                              } else {
                                                await FirebaseFirestore.instance.collection('stocks').add({
                                                  'product_ref': productRef,
                                                  'warehouse_ref': warehouseRef,
                                                  'qty': qty,
                                                });
                                              }
                                              await FirebaseFirestore.instance.runTransaction((transaction) async {
                                                final productSnap = await transaction.get(productRef);
                                                final productData = productSnap.data() as Map<String, dynamic>?;
                                                final currentQty = productData?['qty'] ?? 0;
                                                transaction.update(productRef, {'qty': currentQty + qty});
                                              });
                                            }
                                            await detailDoc.reference.delete();
                                          }
                                          await document.reference.delete();
                                          await _loadInvoices();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddDeliveryPage()),
          );
          await _loadInvoices();
        },
        tooltip: 'Tambah Delivery',
        backgroundColor: Colors.green,
        elevation: 6,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}

class POSInvoiceView extends StatelessWidget {
  final Map<String, dynamic> invoiceData;
  final List<DocumentSnapshot> detailDocs;
  final List<String> refNames;
  final NumberFormat rupiahFormat;

  const POSInvoiceView({
    super.key,
    required this.invoiceData,
    required this.detailDocs,
    required this.refNames,
    required this.rupiahFormat,
  });

  @override
  Widget build(BuildContext context) {
    final postDate = DateTime.tryParse(invoiceData['post_date'] ?? '') ??
        (invoiceData['created_at'] as Timestamp).toDate();
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS View'),
        backgroundColor: Colors.blue[200],
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No Faktur: ${invoiceData['no_faktur']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Tanggal: ${DateFormat('yyyy-MM-dd').format(postDate)}'),
            Text('Customer: ${refNames[0]}'),
            Text('Warehouse: ${refNames[1]}'),
            Text('Salesman: ${refNames[2]}'),
            const SizedBox(height: 12),
            const Divider(thickness: 1),
            const Text('Daftar Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.builder(
                itemCount: detailDocs.length,
                itemBuilder: (context, index) {
                  final detail = detailDocs[index].data() as Map<String, dynamic>;
                  return FutureBuilder<String>(
                    future: FirebaseFirestore.instance
                        .doc(detail['product_ref'].path)
                        .get()
                        .then((snap) => (snap.data() as Map<String, dynamic>)['name'] ?? 'Produk'),
                    builder: (context, snapshot) {
                      final name = snapshot.data ?? '...';
                      return Card(
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text('Qty: ${detail['qty']} ${detail['unit_name']}'),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Harga: ${rupiahFormat.format(detail['price'])}'),
                              Text('Subtotal: ${rupiahFormat.format(detail['subtotal'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Item:', style: TextStyle(fontSize: 16)),
                Text('${invoiceData['item_total']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total:', style: TextStyle(fontSize: 16)),
                Text(rupiahFormat.format(invoiceData['grandtotal']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPage();
}

class _CustomersPage extends State<CustomersPage> {
  List<DocumentSnapshot> _allCustomers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('customers')
        .orderBy('name')
        .get();

    setState(() {
      _allCustomers = snapshot.docs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allCustomers.isEmpty
              ? const Center(child: Text('Tidak ada customer yang ditemukan.'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: IntrinsicWidth(
                          child: DataTable(
                            headingRowHeight: 48,
                            columnSpacing: 24,
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            columns: const [
                              DataColumn(label: Center(child: Text('Nama Toko'))),
                              DataColumn(label: Center(child: Text('Username'))),
                              DataColumn(label: Center(child: Text('Aksi'))),
                            ],
                            rows: _allCustomers.map((document) {
                              final data = document.data() as Map<String, dynamic>;
                              Widget centeredCell(String text) =>
                                  Center(child: Text(text, textAlign: TextAlign.center));

                              return DataRow(
                                cells: [
                                  DataCell(centeredCell(data['name'] ?? '')),
                                  DataCell(centeredCell(data['username'] ?? '')),
                                  DataCell(
                                    Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () async {
                                              final result = await showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                builder: (_) => EditCustomerModal(
                                                  customerRef: document.reference,
                                                ),
                                              );
                                              if (result == 'updated') {
                                                await _loadCustomers();
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Hapus Customer?'),
                                                  content: const Text('Apakah Anda yakin ingin menghapus customer ini?'),
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
                                                await _loadCustomers();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerPage()),
          );
          await _loadCustomers();
        },
        tooltip: 'Tambah Customer',
        backgroundColor: Colors.green,
        elevation: 6,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}

class SalesmenPage extends StatefulWidget {
  const SalesmenPage({super.key});

  @override
  State<SalesmenPage> createState() => _SalesmenPage();
}

class _SalesmenPage extends State<SalesmenPage> {
  List<DocumentSnapshot> _allSalesmen = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSalesmenForCustomer();
  }

  Future<void> _loadSalesmenForCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    final customerRefPath = prefs.getString('customer_ref');
    if (customerRefPath == null || customerRefPath.isEmpty) return;

    final customerRef = FirebaseFirestore.instance.doc(customerRefPath);
    final salesmenSnapshot = await FirebaseFirestore.instance
        .collection('salesmen')
        .where('customer_ref', isEqualTo: customerRef)
        .get();

    setState(() {
      _allSalesmen = salesmenSnapshot.docs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: Text('Memuat data...'))
          : _allSalesmen.isEmpty
              ? const Center(child: Text('Tidak ada salesman.'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: IntrinsicWidth(
                          child: DataTable(
                            headingRowHeight: 48,
                            columnSpacing: 24,
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            columns: const [
                              DataColumn(label: Center(child: Text('Nama'))),
                              DataColumn(label: Center(child: Text('Area'))),
                              DataColumn(label: Center(child: Text('Aksi'))),
                            ],
                            rows: _allSalesmen.map((document) {
                              final data = document.data() as Map<String, dynamic>;
                              Widget centeredCell(String text) =>
                                  Center(child: Text(text, textAlign: TextAlign.center));

                              return DataRow(
                                cells: [
                                  DataCell(centeredCell(data['name'] ?? '')),
                                  DataCell(centeredCell(data['area'] ?? '')),
                                  DataCell(
                                    Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () async {
                                              final result = await showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                builder: (_) => EditSalesmanModal(
                                                  salesmanRef: document.reference,
                                                ),
                                              );
                                              if (result == 'updated') {
                                                await _loadSalesmenForCustomer();
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Hapus Salesman?'),
                                                  content: const Text('Apakah Anda yakin ingin menghapus salesman ini?'),
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
                                                await _loadSalesmenForCustomer();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddSalesmanPage()),
          );
          await _loadSalesmenForCustomer();
        },
        tooltip: 'Tambah Salesman',
        backgroundColor: Colors.green,
        elevation: 6,
        child: const Icon(Icons.add, size: 32),
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
  List<DocumentSnapshot> _allSuppliers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliersForStore();
  }

  Future<void> _loadSuppliersForStore() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('customer_ref');
    if (storeRefPath == null || storeRefPath.isEmpty) return;

    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);
    final receiptsSnapshot = await FirebaseFirestore.instance
        .collection('suppliers')
        .where('customer_ref', isEqualTo: storeRef)
        .get();
    
    List<DocumentSnapshot> allSuppliers= [];

    for (var supplier in receiptsSnapshot.docs) {
      allSuppliers.add(supplier);
    }

    setState(() {
      _allSuppliers = allSuppliers;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: Text('Masukkan kode dan nama toko terlebih dahulu.'))
          : _allSuppliers.isEmpty
              ? const Center(child: Text('Tidak ada detail supplier.'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: IntrinsicWidth(
                          child: DataTable(
                            headingRowHeight: 48,
                            columnSpacing: 24,
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            columns: const [
                              DataColumn(label: Center(child: Text('Nama Supplier'))),
                              DataColumn(label: Center(child: Text('Aksi'))),
                            ],
                            rows: _allSuppliers.map((document) {
                              final data = document.data() as Map<String, dynamic>;
                              Widget centeredCell(String text) => Center(child: Text(text, textAlign: TextAlign.center));

                              return DataRow(
                                cells: [
                                  DataCell(centeredCell(data['name'] ?? '')),
                                  DataCell(
                                    Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
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
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddSupplierPage()),
          );
          await _loadSuppliersForStore();
        },
        tooltip: 'Tambah Supplier',
        backgroundColor: Colors.green,
        elevation: 6,
        child: const Icon(Icons.add, size: 32),
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
  List<DocumentSnapshot> _allWarehouses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWarehousesForStore();
  }

  Future<void> _loadWarehousesForStore() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('customer_ref');
    if (storeRefPath == null || storeRefPath.isEmpty) return;

    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);
    final snapshot = await FirebaseFirestore.instance
        .collection('warehouses')
        .where('customer_ref', isEqualTo: storeRef)
        .get();

    setState(() {
      _allWarehouses = snapshot.docs;
      _loading = false;
    });
  }

  Future<String> _resolveProductName(DocumentReference? ref) async {
    if (ref == null) return 'Unknown';
    try {
      final doc = await ref.get();
      final data = doc.data() as Map<String, dynamic>?;
      return data?['name'] ?? 'Unnamed';
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: Text('Masukkan kode dan nama toko terlebih dahulu.'))
          : _allWarehouses.isEmpty
              ? const Center(child: Text('Tidak ada detail warehouse.'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: IntrinsicWidth(
                          child: DataTable(
                            headingRowHeight: 48,
                            columnSpacing: 24,
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            columns: const [
                              DataColumn(label: Center(child: Text('Nama Warehouse'))),
                              DataColumn(label: Center(child: Text('Aksi'))),
                            ],
                            rows: _allWarehouses.map((document) {
                              final data = document.data() as Map<String, dynamic>;

                              return DataRow(
                                cells: [
                                  DataCell(Center(child: Text(data['name'] ?? ''))),
                                  DataCell(
                                    Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              final stockSnapshot = await FirebaseFirestore.instance
                                                  .collection('stocks')
                                                  .where('warehouse_ref', isEqualTo: document.reference)
                                                  .get();
                                              final stockDocs = stockSnapshot.docs;

                                              showDialog(
                                                context: context,
                                                builder: (context) => Dialog(
                                                  insetPadding: const EdgeInsets.all(24),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(16),
                                                    child: SingleChildScrollView(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Text(
                                                            'Stok Barang',
                                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                          ),
                                                          const SizedBox(height: 12),
                                                          ...stockDocs.map((doc) {
                                                            final stock = doc.data();
                                                            final productRef = stock['product_ref'] as DocumentReference?;
                                                            final qty = stock['qty'];

                                                            return FutureBuilder<String>(
                                                              future: _resolveProductName(productRef),
                                                              builder: (context, snapshot) {
                                                                final productName = snapshot.data ?? 'Loading...';
                                                                return Card(
                                                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                                                  child: Padding(
                                                                    padding: const EdgeInsets.all(12),
                                                                    child: Column(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                                        Text("Qty: $qty"),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          }),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text("Lihat Stok"),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () async {
                                              final result = await showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                builder: (_) => EditWarehouseModal(warehouseRef: document.reference),
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
                                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
                                                  ],
                                                ),
                                              );
                                              if (confirmed == true) {
                                                final stocksSnapshot = await FirebaseFirestore.instance
                                                    .collection('stocks')
                                                    .where('warehouse_ref', isEqualTo: document.reference)
                                                    .get();

                                                for (var stockDoc in stocksSnapshot.docs) {
                                                  final stockData = stockDoc.data();
                                                  final productRef = stockData['product_ref'] as DocumentReference?;
                                                  final qty = stockData['qty'];

                                                  if (productRef != null && qty != null) {
                                                    await FirebaseFirestore.instance.runTransaction((transaction) async {
                                                      final productSnap = await transaction.get(productRef);
                                                      final productData = productSnap.data() as Map<String, dynamic>?;
                                                      final currentQty = productData?['qty'] ?? 0;
                                                      transaction.update(productRef, {'qty': currentQty - qty});
                                                    });
                                                  }
                                                  await stockDoc.reference.delete();
                                                }

                                                await document.reference.delete();
                                                await _loadWarehousesForStore();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddWarehousePage()),
          );
          await _loadWarehousesForStore();
        },
        tooltip: 'Tambah Warehouse',
        backgroundColor: Colors.green,
        elevation: 6,
        child: const Icon(Icons.add, size: 32),
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
    final storeRefPath = prefs.getString('customer_ref');
    if (storeRefPath == null || storeRefPath.isEmpty) return;

    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);
    final receiptsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('customer_ref', isEqualTo: storeRef)
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
      body: _loading
          ? const Center(child: Text('Masukkan kode dan nama toko terlebih dahulu.'))
          : _allProducts.isEmpty
              ? const Center(child: Text('Tidak ada detail produk.'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: IntrinsicWidth(
                          child: DataTable(
                            headingRowHeight: 48,
                            columnSpacing: 24,
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            columns: const [
                              DataColumn(label: Center(child: Text('Nama Product'))),
                              DataColumn(label: Center(child: Text('Qty'))),
                              DataColumn(label: Center(child: Text('Harga Default'))),
                              DataColumn(label: Center(child: Text('Aksi'))),
                            ],
                            rows: _allProducts.map((document) {
                              final data = document.data() as Map<String, dynamic>;
                              Widget centeredCell(String text) => Center(child: Text(text, textAlign: TextAlign.center));
      
                              return DataRow(
                                cells: [
                                  DataCell(centeredCell(data['name'] ?? '')),
                                  DataCell(centeredCell('${data['qty']} pcs')),
                                  DataCell(centeredCell(rupiahFormat.format(data['default_price']))),
                                  DataCell(
                                    Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
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
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductPage()),
          );
          await _loadProductsForStore();
        },
        tooltip: 'Tambah Product',
        backgroundColor: Colors.green,
        elevation: 6,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}

final rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);