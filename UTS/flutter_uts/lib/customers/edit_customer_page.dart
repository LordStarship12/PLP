import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final TextEditingController _storeNameController = TextEditingController();

  bool _isAdmin = false;
  bool _loading = true;

  final Color pastelBlue = const Color(0xFFE3F2FD);
  final Color primaryBlue = const Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final refPath = prefs.getString('customer_ref');
    _isAdmin = refPath == 'customers/admin';

    final doc = await widget.customerRef.get();
    final data = doc.data() as Map<String, dynamic>;

    _usernameController.text = data['username'] ?? '';
    _storeNameController.text = data['name'] ?? '';
    _loading = false;

    if (mounted) setState(() {});
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final updates = {
      'name': _storeNameController.text.trim(),
    };

    if (_isAdmin) {
      final newUsername = _usernameController.text.trim();
      final query = await FirebaseFirestore.instance
          .collection('customers')
          .where('username', isEqualTo: newUsername)
          .limit(1)
          .get();

      final isSameDoc = query.docs.isNotEmpty &&
          query.docs.first.reference.path == widget.customerRef.path;

      if (query.docs.isNotEmpty && !isSameDoc) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Username sudah dipakai.")),
        );
        return;
      }

      updates['username'] = newUsername;

      final newPassword = _passwordController.text.trim();
      if (newPassword.isNotEmpty) {
        updates['password'] = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      }
    }

    await widget.customerRef.update(updates);

    if (mounted) Navigator.pop(context, 'updated');
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Container(
            color: pastelBlue,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Edit Customer',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    if (_isAdmin) ...[
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText:
                              'Password (kosongkan jika tidak diganti)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _storeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Toko',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Simpan Perubahan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
