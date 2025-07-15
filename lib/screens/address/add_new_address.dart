import 'package:buy_app/services/addresses.dart';
import 'package:buy_app/widgets/auth_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddAddressPage extends StatefulWidget {
  @override
  _AddAddressPageState createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final first = TextEditingController();
  final last = TextEditingController();
  final line1 = TextEditingController();
  final line2 = TextEditingController();
  final city = TextEditingController();
  final pincode = TextEditingController();
  final state = TextEditingController();
  void saveAddress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final address = Address(
      id: '',
      first: first.text,
      last: last.text,
      line1: line1.text,
      line2: line2.text,
      city: city.text,
      state: state.text,
      pincode: pincode.text,
    );

    await FirebaseFirestore.instance
        .collection('customers')
        .doc(uid)
        .collection('addresses')
        .add(address.toMap());

    Navigator.pop(context); // Go back to address selection
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Address")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AuthTextField(hintText: "First Name", controller: first),
            AuthTextField(hintText: "Last Name", controller: last),
            AuthTextField(hintText: "Address Line 1", controller: line1),
            AuthTextField(hintText: "Address Line 2", controller: line2),
            AuthTextField(hintText: "City", controller: city),
            AuthTextField(hintText: "State", controller: state),
            AuthTextField(hintText: "Pincode", controller: pincode),
            SizedBox(height: 20),
            ElevatedButton(onPressed: saveAddress, child: Text("Save Address")),
          ],
        ),
      ),
    );
  }
}
