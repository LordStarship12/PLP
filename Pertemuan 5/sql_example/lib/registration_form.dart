import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'user.dart';

class RegistrationForm extends StatefulWidget {
  final VoidCallback onUserAdded;

  const RegistrationForm({super.key, required this.onUserAdded});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  String _username = '';
  String _email = '';

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final newUser = User(username: _username, email: _email);
      await DatabaseHelper.instance.insertUser(newUser);

      widget.onUserAdded();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Register User'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Username'),
              onSaved: (value) {
                if (value != null) _username = value;
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a username';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              onSaved: (value) {
                if (value != null) _email = value;
              },
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _submit, child: const Text('Submit')),
        TextButton(
          onPressed: () {
            if (mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
