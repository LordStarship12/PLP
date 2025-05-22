  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  class AddWarehousePage extends StatefulWidget{
    const AddWarehousePage({super.key});

    @override
    State<AddWarehousePage> createState() => _AddWarehousePageState();
  }

  class _AddWarehousePageState extends State<AddWarehousePage> {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _warehouseController = TextEditingController();

    void _saveWarehouse() async {
      if (_formKey.currentState!.validate()) {
        final prefs = await SharedPreferences.getInstance();
        
        final storeRefPath = prefs.getString('store_ref');
        if (storeRefPath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Store reference not found.")),
          );
          return;
        }

        final storeRef = FirebaseFirestore.instance.doc(storeRefPath);

        await FirebaseFirestore.instance.collection('warehouses').add({
          'name': _warehouseController.text.trim(),
          'store_ref': storeRef,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Warehouse berhasil ditambahkan.")),
        );

        if (mounted) Navigator.pop(context);
      }
    }


    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text("Tambah Warehouse")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _warehouseController,
                  decoration: InputDecoration(labelText: 'Nama Warehouse'),
                  validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveWarehouse,
                  child: Text('Simpan Warehouse'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

