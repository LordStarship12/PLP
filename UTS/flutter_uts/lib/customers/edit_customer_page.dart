import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';

class EditCustomerModal extends StatefulWidget {
  final DocumentReference customerRef;

  const EditCustomerModal({
    super.key,
    required this.customerRef,
  });

  @override
  State<EditCustomerModal> createState() => _EditCustomerModalState();
}

class _EditCustomerModalState extends State<EditCustomerModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    try {
      final doc = await widget.customerRef.get();
      final data = doc.data() as Map<String, dynamic>?;
      _usernameController.text = data?['username'] ?? '';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat data customer.')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    final newUsername = _usernameController.text.trim();
    final newPassword = _passwordController.text.trim();

    final updateData = {
      'username': newUsername,
      'updated_at': DateTime.now(),
    };

    // Only hash and update password if it's not empty
    if (newPassword.isNotEmpty) {
      updateData['password'] = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    }

    await widget.customerRef.update(updateData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Customer berhasil diedit.")),
    );

    if (mounted) {
      Navigator.pop(context, 'updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Customer')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password (kosongkan jika tidak ingin diubah)',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updateCustomer,
                      child: const Text('Update Customer'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
