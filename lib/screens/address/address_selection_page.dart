import 'package:buy_app/widgets/normal_button.dart';
import 'package:buy_app/widgets/outline_button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buy_app/services/addresses.dart';

class AddressSelectionPage extends StatefulWidget {
  @override
  State<AddressSelectionPage> createState() => _AddressSelectionPageState();
}

class _AddressSelectionPageState extends State<AddressSelectionPage> {
  List<Address> addressList = [];
  String? selectedAddressId;

  @override
  void initState() {
    super.initState();
    loadAddresses();
  }

  Future<void> loadAddresses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('customers')
        .doc(uid)
        .collection('addresses')
        .get();

    final addresses = snapshot.docs.map((doc) {
      return Address.fromMap(doc.data(), doc.id);
    }).toList();

    setState(() {
      addressList = addresses;
      if (addresses.isNotEmpty) {
        selectedAddressId = addresses.first.id;
      }
    });
  }

  void addAddress() {
    Navigator.pushNamed(context, '/add_address').then((_) => loadAddresses());
  }

  void selectAddress() {
    if (selectedAddressId == null) return;
    final selected = addressList.firstWhere((a) => a.id == selectedAddressId);
    print('Selected address: ${selected.line1}, ${selected.cityState}');
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: selected,
    ); // Pass back selected address
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Address")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: addressList.length,
              itemBuilder: (context, index) {
                final address = addressList[index];
                return Card(
                  child: RadioListTile(
                    value: address.id,
                    groupValue: selectedAddressId,
                    onChanged: (value) {
                      setState(() {
                        selectedAddressId = value as String;
                      });
                    },
                    title: Text("Address ${index + 1}"),
                    subtitle: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "\n${address.line1}, \n\n${address.line2},\n\n${address.cityState} - ${address.pincode}",
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          //TextButton(onPressed: addAddress, child: Text('Add new Address')),
          Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: NormalButton(
                      hintText: 'Use this Address',
                      onPressed: selectAddress,
                      height: 55,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              const SizedBox(height: 10),
              Text('or'),
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomOutlineButton(
                      hintText: 'Add new Address',
                      onPressed: addAddress,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
