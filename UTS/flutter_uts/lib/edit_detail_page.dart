import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditDetailPage extends StatefulWidget {
  final DocumentSnapshot document;

  const EditDetailPage({super.key, required this.document});

  @override
  _EditDetailPageState createState() => _EditDetailPageState();
}

class _EditDetailPageState extends State<EditDetailPage> {
  late TextEditingController _formNumberController;
  late TextEditingController _grandTotalController;
  late TextEditingController _itemTotalController;

  DocumentReference? _selectedSupplier;
  DocumentReference? _selectedWarehouse;

  List<DocumentSnapshot> _suppliers = [];
  List<DocumentSnapshot> _warehouses = [];

  @override
  void initState() {
    super.initState();
    final data = widget.document.data()! as Map<String, dynamic>;
    _formNumberController = TextEditingController(text: data['no_form']);
    _grandTotalController = TextEditingController(text: data['grandtotal'].toString());
    _itemTotalController = TextEditingController(text: data['item_total'].toString());

    _selectedSupplier = data['supplier_ref'];
    _selectedWarehouse = data['warehouse_ref'];

    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    final supplierSnapshot = await FirebaseFirestore.instance.collection('suppliers').get();
    final warehouseSnapshot = await FirebaseFirestore.instance.collection('warehouses').get();

    setState(() {
      _suppliers = supplierSnapshot.docs;
      _warehouses = warehouseSnapshot.docs;
    });
  }

  void _updateReceipt() async {
    await widget.document.reference.update({
      'no_form': _formNumberController.text.trim(),
      'grandtotal': int.parse(_grandTotalController.text.trim()),
      'item_total': int.parse(_itemTotalController.text.trim()),
      'supplier_ref': _selectedSupplier,
      'warehouse_ref': _selectedWarehouse,
    });

    if (mounted) Navigator.pop(context);
  }

  void _deleteReceipt() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hapus Receipt"),
        content: Text("Apakah Anda yakin ingin menghapus receipt ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.document.reference.delete();
      if (mounted) Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Edit Receipt", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _formNumberController,
              decoration: InputDecoration(labelText: "No. Form"),
            ),
            TextFormField(
              controller: _grandTotalController,
              decoration: InputDecoration(labelText: "Grand Total"),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _itemTotalController,
              decoration: InputDecoration(labelText: "Item Total"),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<DocumentReference>(
              value: _selectedSupplier,
              items: _suppliers.map((doc) {
                return DropdownMenuItem(
                  value: doc.reference,
                  child: Text(doc['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSupplier = value;
                });
              },
              decoration: InputDecoration(labelText: "Supplier"),
            ),
            DropdownButtonFormField<DocumentReference>(
              value: _selectedWarehouse,
              items: _warehouses.map((doc) {
                return DropdownMenuItem(
                  value: doc.reference,
                  child: Text(doc['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedWarehouse = value;
                });
              },
              decoration: InputDecoration(labelText: "Warehouse"),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateReceipt,
                    child: Text("Simpan"),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _deleteReceipt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Hapus"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
