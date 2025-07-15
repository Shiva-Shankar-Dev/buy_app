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
    if (uid == null) {
      print("❌ No user logged in");
      return;
    }

    print("🔍 Loading addresses for user: $uid");

    final snapshot = await FirebaseFirestore.instance
        .collection('customers')
        .doc(uid)
        .collection('addresses')
        .get();

    print("📊 Found ${snapshot.docs.length} addresses");

    final addresses = snapshot.docs.map((doc) {
      print("📝 Document data: ${doc.data()}");
      final address = Address.fromMap(doc.data(), doc.id);
      print(
        "✅ Parsed address: first='${address.first}', last='${address.last}', line1='${address.line1}', city='${address.city}', state='${address.state}'",
      );
      return address;
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
    print('Selected address: ${selected.line1}, ${selected.city}');
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
                    title: Text(
                      "${address.first.isEmpty ? 'No' : address.first} ${address.last.isEmpty ? 'Name' : address.last}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address.line1.isEmpty
                                ? "No address line 1"
                                : address.line1,
                            style: TextStyle(fontSize: 14),
                          ),
                          if (address.line2.isNotEmpty)
                            Text(address.line2, style: TextStyle(fontSize: 14)),
                          SizedBox(height: 4),
                          Text(
                            "${address.city.isEmpty ? 'No City' : address.city}, ${address.state.isEmpty ? 'No State' : address.state} - ${address.pincode.isEmpty ? 'No PIN' : address.pincode}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          // Debug info - remove this later
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "DEBUG: first='${address.first}', last='${address.last}', state='${address.state}'",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
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
