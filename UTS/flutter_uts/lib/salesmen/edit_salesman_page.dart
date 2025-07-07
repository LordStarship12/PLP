import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSalesmanModal extends StatefulWidget {
  final DocumentReference salesmanRef;

  const EditSalesmanModal({
    super.key,
    required this.salesmanRef,
  });

  @override
  State<EditSalesmanModal> createState() => _EditSalesmanModalState();
}

class _EditSalesmanModalState extends State<EditSalesmanModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  bool _loading = true;

  final Color pastelBlue = const Color(0xFFE3F2FD);
  final Color primaryBlue = const Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _loadSalesmanData();
  }

  Future<void> _loadSalesmanData() async {
    try {
      final doc = await widget.salesmanRef.get();
      final data = doc.data() as Map<String, dynamic>?;
      _nameController.text = data?['name'] ?? '';
      _areaController.text = data?['area'] ?? '';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat data salesman')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateSalesman() async {
    if (!_formKey.currentState!.validate()) return;

    await widget.salesmanRef.update({
      'name': _nameController.text.trim(),
      'area': _areaController.text.trim(),
      'updated_at': DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Salesman berhasil diedit.")),
    );

    if (mounted) Navigator.pop(context, 'updated');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelBlue,
      appBar: AppBar(title: const Text('Edit Salesman')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Salesman',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _areaController,
                      decoration: const InputDecoration(
                        labelText: 'Area Penjualan',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateSalesman,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Update Salesman'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
