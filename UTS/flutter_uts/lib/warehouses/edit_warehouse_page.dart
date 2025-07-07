import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditWarehouseModal extends StatefulWidget {
  final DocumentReference warehouseRef;

  const EditWarehouseModal({
    super.key,
    required this.warehouseRef,
  });

  @override
  State<EditWarehouseModal> createState() => _EditWarehouseModalState();
}

class _EditWarehouseModalState extends State<EditWarehouseModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _warehouseNameController = TextEditingController();
  bool _loading = true;

  final Color pastelBlue = const Color(0xFFE3F2FD);
  final Color primaryBlue = const Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _loadWarehouseData();
  }

  Future<void> _loadWarehouseData() async {
    try {
      final doc = await widget.warehouseRef.get();
      final data = doc.data() as Map<String, dynamic>?;
      _warehouseNameController.text = data?['name'] ?? '';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load warehouse data')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    await widget.warehouseRef.update({
      'name': _warehouseNameController.text.trim(),
      'updated_at': DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Warehouse berhasil diedit.")),
    );

    if (mounted) Navigator.pop(context, 'updated');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelBlue,
      appBar: AppBar(title: const Text('Edit Warehouse')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _warehouseNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Warehouse',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updateSupplier,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Update Warehouse'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
