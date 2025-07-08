import 'package:buy_app/services/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  AuthService _authService = AuthService();
  Future<DocumentSnapshot>? details;
  void loadUser() async {
    try {
      _authService.getCurrentUID();
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(_authService.getCurrentUID())
          .get();
    } catch (e) {
      print("$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    loadUser();
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Row(children: [Text('${details}')]),
          ],
        ),
      ),
    );
  }
}
