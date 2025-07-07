import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:bcrypt/bcrypt.dart';

import 'deliveries/add_delivery_page.dart';
import 'deliveries/edit_delivery_page.dart';
import 'deliveries/pos_invoice_pdf.dart';
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
import 'warehouses/warehouse_mutation_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);

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

      // Only allow login if customer_ref is either not present or null
      if (data.containsKey('customer_ref') && data['customer_ref'] != null) {
        setState(() {
          _error = "Akun ini bukan akun login.";
          _loading = false;
        });
        return;
      }

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
      print("Login error: $e");
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
  String? _refPath;
  bool _loading = true;

  final List<Widget> _storePages = [
    const ReceiptListPage(),
    const DeliveryListPage(),
    const CustomersPage(),
    const SalesmenPage(),
    const SuppliersPage(),
    const WarehousesPage(),
    const ProductsPage(),
  ];

  final List<String> _storeTitles = [
    'Receipts',
    'Sales Invoices',
    'Customers',
    'Salesmen',
    'Suppliers',
    'Warehouses',
    'Products',
  ];

  final List<Widget> _adminPages = [
    const CustomersPage(),
  ];

  final List<String> _adminTitles = [
    'Customers',
  ];

  Future<void> _loadRefPath() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _refPath = prefs.getString('customer_ref');
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRefPath();
  }

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isAdmin = _refPath == 'customers/admin';
    final pages = isAdmin ? _adminPages : _storePages;
    final titles = isAdmin ? _adminTitles : _storeTitles;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.cyan),
              child: Text('UAS PALP 2025', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.store_outlined),
                title: const Text('Customers'),
                onTap: () => _onDrawerItemTapped(0),
              )
            else ...[
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
            ],
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
      body: pages[_selectedIndex],
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
  final NumberFormat rupiahFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final Color pastelBlue = const Color(0xFFE3F2FD);
  final Color pastelBlueDark = const Color(0xFF90CAF9);
  final Color textDark = const Color(0xFF333333);

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
    DocumentReference? supplierRef,
    DocumentReference? warehouseRef,
  ) async {
    final refs = [supplierRef, warehouseRef];
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

  DataColumn centeredColumn(String label, {double width = 180}) {
    return DataColumn(
      label: SizedBox(
        width: width,
        child: Center(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  DataCell centeredCell(Widget child, {double width = 180}) {
    return DataCell(
      SizedBox(
        width: width,
        child: Center(
          child: DefaultTextStyle(style: TextStyle(color: textDark), child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelBlue,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allReceipts.isEmpty
              ? const Center(child: Text('Tidak ada receipt'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(pastelBlueDark),
                    dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) => states.contains(WidgetState.selected)
                          ? pastelBlueDark.withOpacity(0.4)
                          : Colors.white,
                    ),
                    columns: [
                      centeredColumn('Form'),
                      centeredColumn('Tanggal'),
                      centeredColumn('Total'),
                      centeredColumn('Items'),
                      centeredColumn('Supplier'),
                      centeredColumn('Warehouse'),
                      centeredColumn('Detail'),
                      centeredColumn('Aksi'),
                    ],
                    rows: _allReceipts.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final postDate = DateTime.tryParse(data['post_date'] ?? '') ??
                          (data['created_at'] as Timestamp).toDate();
                      final namesFuture = _resolveReferences(
                        data['supplier_ref'],
                        data['warehouse_ref'],
                      );

                      return DataRow(cells: [
                        centeredCell(Text(data['no_form'] ?? '-')),
                        centeredCell(Text(DateFormat('yyyy-MM-dd').format(postDate))),
                        centeredCell(Text(rupiahFormat.format(data['grandtotal'] ?? 0))),
                        centeredCell(Text('${data['item_total'] ?? 0}')),

                        for (int i = 0; i < 2; i++)
                          centeredCell(
                            FutureBuilder<List<String>>(
                              future: namesFuture,
                              builder: (ctx, snap) {
                                final name = snap.data != null ? snap.data![i] : '-';
                                return Tooltip(
                                  message: name,
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              },
                            ),
                          ),

                        centeredCell(
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: pastelBlueDark,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.info_outline),
                            label: const Text("Detail"),
                            onPressed: () async {
                              final detailSnapshot = await doc.reference.collection('details').get();
                              final detailDocs = detailSnapshot.docs;

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
                                        children: detailDocs.map((doc) {
                                          final detail = doc.data();
                                          return FutureBuilder<String>(
                                            future: _resolveProductName(detail['product_ref']),
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
                                                      Text("Qty: ${detail['qty']} ${detail['unit_name']}"),
                                                      Text("Harga: ${rupiahFormat.format(detail['price'])}"),
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
                          ),
                        ),

                        centeredCell(Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              tooltip: 'Edit Receipt',
                              onPressed: () async {
                                final result = await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => EditReceiptModal(
                                    receiptRef: doc.reference,
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
                              tooltip: 'Hapus Receipt',
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

                                if (confirmed != true) return;

                                final detailsSnapshot = await doc.reference.collection('details').get();
                                for (final detailDoc in detailsSnapshot.docs) {
                                  final detailData = detailDoc.data();
                                  final productRef = detailData['product_ref'];
                                  final warehouseRef = detailData['warehouse_ref'] ?? data['warehouse_ref'];
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
                                      final newQty = (stockDoc['qty'] ?? 0) - qty;
                                      if (newQty <= 0) {
                                        await stockDoc.reference.delete();
                                      } else {
                                        await stockDoc.reference.update({'qty': newQty});
                                      }
                                    }

                                    final productSnap = await productRef.get();
                                    if (productSnap.exists) {
                                      final currentQty = (productSnap.data() as Map)['qty'] ?? 0;
                                      await productRef.update({'qty': currentQty - qty});
                                    }

                                    await detailDoc.reference.delete();
                                  }
                                }

                                await doc.reference.delete();
                                await _loadReceiptsForStore();
                              },
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddReceiptPage()),
          );
          await _loadReceiptsForStore();
        },
        backgroundColor: pastelBlueDark,
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
  List<DocumentSnapshot> _allDeliveries = [];
  bool _loading = true;
  final NumberFormat rupiahFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final Color pastelBlue = const Color(0xFFE3F2FD);
  final Color pastelBlueDark = const Color(0xFF90CAF9);
  final Color textDark = const Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _loadDeliveriesForStore();
  }

  Future<void> _loadDeliveriesForStore() async {
    final prefs = await SharedPreferences.getInstance();
    final storeRefPath = prefs.getString('customer_ref');
    if (storeRefPath == null || storeRefPath.isEmpty) return;

    final storeRef = FirebaseFirestore.instance.doc(storeRefPath);
    final deliveriesSnapshot = await FirebaseFirestore.instance
        .collection('deliveries')
        .where('customer_ref', isEqualTo: storeRef)
        .get();

    setState(() {
      _allDeliveries = deliveriesSnapshot.docs;
      _loading = false;
    });
  }

  Future<List<String>> _resolveReferences(
    DocumentReference? customerStoreRef,
    DocumentReference? warehouseRef,
    DocumentReference? salesmanRef,
  ) async {
    final refs = [customerStoreRef, warehouseRef, salesmanRef];
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

  DataColumn centeredColumn(String label, {double width = 160}) {
    return DataColumn(
      label: SizedBox(
        width: width,
        child: Center(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  DataCell centeredCell(Widget child, {double width = 160}) {
    return DataCell(
      SizedBox(
        width: width,
        child: Center(
          child: DefaultTextStyle(style: TextStyle(color: textDark), child: child),
        ),
      ),
    );
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
      backgroundColor: pastelBlue,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allDeliveries.isEmpty
              ? const Center(child: Text('Tidak ada delivery'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(pastelBlueDark),
                    dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) => states.contains(WidgetState.selected)
                          ? pastelBlueDark.withOpacity(0.4)
                          : Colors.white,
                    ),
                    columns: [
                      centeredColumn('No. Faktur'),
                      centeredColumn('Tanggal'),
                      centeredColumn('Total'),
                      centeredColumn('Items'),
                      centeredColumn('Customer'),
                      centeredColumn('Warehouse'),
                      centeredColumn('Salesman'),
                      centeredColumn('Detail'),  // <-- added column
                      centeredColumn('Aksi'),
                    ],
                    rows: _allDeliveries.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final postDate = DateTime.tryParse(data['post_date'] ?? '') ??
                          (data['created_at'] as Timestamp).toDate();
                      final refsFut = _resolveReferences(
                        data['customer_store_ref'],
                        data['warehouse_ref'],
                        data['salesman_ref'],
                      );
                      return DataRow(cells: [
                        centeredCell(Text(data['no_faktur'] ?? '-')),
                        centeredCell(Text(DateFormat('yyyy-MM-dd').format(postDate))),
                        centeredCell(Text(rupiahFormat.format(data['grandtotal'] ?? 0))),
                        centeredCell(Text('${data['item_total'] ?? 0}')),
                        for (int i = 0; i < 3; i++)
                          centeredCell(
                            FutureBuilder<List<String>>(
                              future: refsFut,
                              builder: (ctx, snap) {
                                final txt = (snap.data != null ? snap.data![i] : '-');
                                return Tooltip(
                                  message: txt,
                                  child: Text(txt, overflow: TextOverflow.ellipsis, maxLines: 1),
                                );
                              },
                            ),
                          ),
                        // **DETAIL BUTTON** re-added here:
                        centeredCell(
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: pastelBlueDark,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.info_outline),
                            label: const Text("Detail"),
                            onPressed: () async {
                              final detailSnapshot = await doc.reference.collection('details').get();
                              final detailDocs = detailSnapshot.docs;
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
                                        children: detailDocs.map((dd) {
                                          final detail = dd.data();
                                          return FutureBuilder<String>(
                                            future: _resolveProductName(detail['product_ref']),
                                            builder: (context, snapP) {
                                              final pname = snapP.data ?? 'Loading...';
                                              return Card(
                                                margin: const EdgeInsets.symmetric(vertical: 6),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(pname, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                      Text("Qty: ${detail['qty']}"),
                                                      Text("Harga: ${rupiahFormat.format(detail['price'])}"),
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
                          ),
                        ),
                        centeredCell(Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.print, color: Colors.blue),
                              tooltip: 'Print Faktur',
                              onPressed: () async {
                                final details = await doc.reference.collection('details').get();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => POSInvoicePDFPreview(
                                      invoiceData: data,
                                      detailDocs: details.docs,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () async {
                                final result = await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => EditDeliveryModal(
                                    invoiceRef: doc.reference,
                                    invoiceData: data,
                                  ),
                                );
                                if (result == 'updated') {
                                  await _loadDeliveriesForStore();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Hapus Delivery?'),
                                    content: const Text('Apakah Anda yakin ingin menghapus delivery ini?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                                await doc.reference.collection('details').get().then((snap) {
                                  for (var dd in snap.docs) dd.reference.delete();
                                });
                                await doc.reference.delete();
                                await _loadDeliveriesForStore();
                              },
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => AddDeliveryPage()));
          await _loadDeliveriesForStore();
        },
        backgroundColor: pastelBlueDark,
        child: const Icon(Icons.add, size: 32),
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

  final Color pastelBlue = const Color(0xFFE3F2FD);
  final Color pastelBlueDark = const Color(0xFF90CAF9);
  final Color textDark = const Color(0xFF333333);

  late DocumentReference currentUserRef;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final refPath = prefs.getString('customer_ref');
    if (refPath == null) return;

    currentUserRef = FirebaseFirestore.instance.doc(refPath);
    isAdmin = refPath == 'customers/admin';

    QuerySnapshot snapshot;

    if (isAdmin) {
      snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('customer_ref', isNull: true)
          .get();

      setState(() {
        _allCustomers = snapshot.docs
          ..removeWhere((doc) => doc.reference.path == 'customers/admin');
        _loading = false;
      });
    } else {
      // Store user: show customers linked to their store
      snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('customer_ref', isEqualTo: currentUserRef)
          .get();

      setState(() {
        _allCustomers = snapshot.docs;
        _loading = false;
      });
    }
  }

  DataColumn centeredColumn(String label, {double width = 140}) {
    return DataColumn(
      label: SizedBox(
        width: width,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  DataCell centeredCell(Widget child, {double width = 140}) {
    return DataCell(
      SizedBox(
        width: width,
        child: Center(
          child: DefaultTextStyle(style: TextStyle(color: textDark), child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelBlue,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allCustomers.isEmpty
              ? const Center(child: Text('Tidak ada customer yang ditemukan.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(pastelBlueDark),
                    dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) => states.contains(WidgetState.selected)
                          ? pastelBlueDark.withOpacity(0.4)
                          : Colors.white,
                    ),
                    columns: [
                      centeredColumn('Nama Toko'),
                      if (isAdmin) centeredColumn('Username'),
                      centeredColumn('Aksi'),
                    ],
                    rows: _allCustomers.map((document) {
                      final data = document.data() as Map<String, dynamic>;

                      return DataRow(
                        cells: [
                          centeredCell(Text(data['name'] ?? '-')),
                          if (isAdmin) centeredCell(Text(data['username'] ?? '-')),
                          centeredCell(Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
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
                          )),
                        ],
                      );
                    }).toList(),
                  ),
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
        backgroundColor: pastelBlueDark,
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

  final Color pastelBlue = const Color(0xFFE3F2FD);
  final Color pastelBlueDark = const Color(0xFF90CAF9);
  final Color textDark = const Color(0xFF333333);

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

  DataColumn centeredColumn(String label, {double width = 140}) {
    return DataColumn(
      label: SizedBox(
        width: width,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  DataCell centeredCell(Widget child, {double width = 140}) {
    return DataCell(
      SizedBox(
        width: width,
        child: Center(
          child: DefaultTextStyle(
            style: TextStyle(color: textDark),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelBlue,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allSalesmen.isEmpty
              ? const Center(child: Text('Tidak ada salesman.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(pastelBlueDark),
                    dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                      return states.contains(WidgetState.selected)
                          ? pastelBlueDark.withOpacity(0.4)
                          : Colors.white;
                    }),
                    columns: [
                      centeredColumn('Nama'),
                      centeredColumn('Area'),
                      centeredColumn('Aksi'),
                    ],
                    rows: _allSalesmen.map((document) {
                      final data = document.data() as Map<String, dynamic>;

                      return DataRow(
                        cells: [
                          centeredCell(Text(data['name'] ?? '-')),
                          centeredCell(Text(data['area'] ?? '-')),
                          centeredCell(Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
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
                          )),
                        ],
                      );
                    }).toList(),
                  ),
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
        backgroundColor: pastelBlueDark,
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

  final Color pastelBlue = const Color(0xFFE3F2FD);
  final Color pastelBlueDark = const Color(0xFF90CAF9);
  final Color textDark = const Color(0xFF333333);

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

    setState(() {
      _allSuppliers = receiptsSnapshot.docs;
      _loading = false;
    });
  }

  DataColumn centeredColumn(String label, {double width = 180}) {
    return DataColumn(
      label: SizedBox(
        width: width,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  DataCell centeredCell(Widget child, {double width = 180}) {
    return DataCell(
      SizedBox(
        width: width,
        child: Center(
          child: DefaultTextStyle(
            style: TextStyle(color: textDark),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelBlue,
      body: _loading
          ? const Center(child: Text('Masukkan kode dan nama toko terlebih dahulu.'))
          : _allSuppliers.isEmpty
              ? const Center(child: Text('Tidak ada detail supplier.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(pastelBlueDark),
                    dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                      return states.contains(WidgetState.selected)
                          ? pastelBlueDark.withOpacity(0.4)
                          : Colors.white;
                    }),
                    columns: [
                      centeredColumn('Nama Supplier'),
                      centeredColumn('Aksi'),
                    ],
                    rows: _allSuppliers.map((document) {
                      final data = document.data() as Map<String, dynamic>;
                    
                      return DataRow(
                        cells: [
                          centeredCell(Text(data['name'] ?? '-')),
                          centeredCell(
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
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
                        ],
                      );
                    }).toList(),
                  ),
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
        backgroundColor: pastelBlueDark,
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

  final Color pastelBlue = const Color(0xFFE3F2FD);
  final Color pastelBlueDark = const Color(0xFF90CAF9);
  final Color textDark = const Color(0xFF333333);

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

  DataColumn centeredColumn(String label, {double width = 180}) {
    return DataColumn(
      label: SizedBox(
        width: width,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  DataCell centeredCell(Widget child, {double width = 180}) {
    return DataCell(
      SizedBox(
        width: width,
        child: Center(
          child: DefaultTextStyle(
            style: TextStyle(color: textDark),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelBlue,
      body: _loading
          ? const Center(child: Text('Masukkan kode dan nama toko terlebih dahulu.'))
          : _allWarehouses.isEmpty
              ? const Center(child: Text('Tidak ada detail warehouse.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(pastelBlueDark),
                    dataRowColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? pastelBlueDark.withOpacity(0.4)
                          : Colors.white;
                    }),
                    columns: [
                      centeredColumn('Nama Warehouse'),
                      centeredColumn('Lihat Stok'),
                      centeredColumn('Aksi', width: 240),
                    ],
                    rows: _allWarehouses.map((document) {
                      final data = document.data() as Map<String, dynamic>;

                      return DataRow(
                        cells: [
                          centeredCell(Text(data['name'] ?? '')),
                          centeredCell(
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: pastelBlueDark,
                                foregroundColor: Colors.white,
                              ),
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
                          ),
                          centeredCell(
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
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
                            width: 240,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'mutasi_stok',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WarehouseMutationPage()),
              );
              if (result == 'mutated') {
                await _loadWarehousesForStore();
              }
            },
            backgroundColor: Colors.green,
            tooltip: 'Mutasi Stok',
            child: const Icon(Icons.sync_alt),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'tambah_warehouse',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddWarehousePage()),
              );
              await _loadWarehousesForStore();
            },
            backgroundColor: pastelBlueDark,
            tooltip: 'Tambah Warehouse',
            child: const Icon(Icons.add, size: 32),
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

  final Color pastelBlue = const Color(0xFFE3F2FD);
  final Color pastelBlueDark = const Color(0xFF90CAF9);
  final Color textDark = const Color(0xFF333333);

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
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('customer_ref', isEqualTo: storeRef)
        .get();

    setState(() {
      _allProducts = snapshot.docs;
      _loading = false;
    });
  }

  DataColumn centeredColumn(String label, {double width = 180}) {
    return DataColumn(
      label: SizedBox(
        width: width,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  DataCell centeredCell(Widget child, {double width = 180}) {
    return DataCell(
      SizedBox(
        width: width,
        child: Center(
          child: DefaultTextStyle(
            style: TextStyle(color: textDark),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelBlue,
      body: _loading
          ? const Center(child: Text('Masukkan kode dan nama toko terlebih dahulu.'))
          : _allProducts.isEmpty
              ? const Center(child: Text('Tidak ada detail produk.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(pastelBlueDark),
                    dataRowColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? pastelBlueDark.withOpacity(0.4)
                          : Colors.white;
                    }),
                    columns: [
                      centeredColumn('Nama Product'),
                      centeredColumn('Qty'),
                      centeredColumn('Harga Default'),
                      centeredColumn('Aksi', width: 240),
                    ],
                    rows: _allProducts.map((document) {
                      final data = document.data() as Map<String, dynamic>;
                      final String name = data['name'] ?? '-';
                      final int qty = data['qty'] ?? 0;
                      final int price = data['default_price'] ?? 0;

                      return DataRow(
                        cells: [
                          centeredCell(Text(name)),
                          centeredCell(Text('$qty pcs')),
                          centeredCell(Text(rupiahFormat.format(price))),
                          centeredCell(
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
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
                                        title: const Text('Hapus Produk?'),
                                        content: const Text(
                                          'Apakah Anda yakin ingin menghapus produk ini? Semua stok, faktur pembelian, dan pengiriman yang terkait juga akan dihapus.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Batal'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                                            child: const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      final productRef = document.reference;
                                      final firestore = FirebaseFirestore.instance;

                                      final receiptSnapshot = await firestore.collection('purchaseGoodsReceipts').get();
                                      for (final doc in receiptSnapshot.docs) {
                                        final items = List<Map<String, dynamic>>.from(doc['items'] ?? []);
                                        final hasProduct = items.any((item) =>
                                            (item['product_ref'] as DocumentReference?)?.path == productRef.path);
                                        if (hasProduct) {
                                          await doc.reference.delete();
                                        }
                                      }
                                      final deliverySnapshot = await firestore.collection('deliveries').get();
                                      for (final doc in deliverySnapshot.docs) {
                                        final items = List<Map<String, dynamic>>.from(doc['items'] ?? []);
                                        final hasProduct = items.any((item) =>
                                            (item['product_ref'] as DocumentReference?)?.path == productRef.path);
                                        if (hasProduct) {
                                          await doc.reference.delete();
                                        }
                                      }
                                      final stockSnapshot = await firestore
                                          .collection('stocks')
                                          .where('product_ref', isEqualTo: productRef)
                                          .get();
                                      for (final stockDoc in stockSnapshot.docs) {
                                        await stockDoc.reference.delete();
                                      }
                                      await productRef.delete();
                                      await _loadProductsForStore();

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Produk dan semua data terkait berhasil dihapus.')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            width: 240,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
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
        backgroundColor: pastelBlueDark,
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