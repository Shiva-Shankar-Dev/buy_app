// ignore_for_file: deprecated_member_use

import 'package:buy_app/widgets/normal_button.dart';
import 'package:buy_app/widgets/outline_button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buy_app/services/addresses.dart';
import 'package:buy_app/services/selected_address_service.dart';

class AddressSelectionPage extends StatefulWidget {
  const AddressSelectionPage({super.key});

  @override
  State<AddressSelectionPage> createState() => _AddressSelectionPageState();
}

class _AddressSelectionPageState extends State<AddressSelectionPage> {
  List<Address> addressList = [];
  String? selectedAddressId;
  final selectedAddressService = SelectedAddressService.instance;

  @override
  void initState() {
    super.initState();
    loadAddresses();
  }

  Future<void> loadAddresses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint("❌ No user logged in");
      return;
    }

    debugPrint("🔍 Loading addresses for user: $uid");

    final snapshot = await FirebaseFirestore.instance
        .collection('customers')
        .doc(uid)
        .collection('addresses')
        .get();

    debugPrint("📊 Found ${snapshot.docs.length} addresses");

    final addresses = snapshot.docs.map((doc) {
      debugPrint("📝 Document data: ${doc.data()}");
      final address = Address.fromMap(doc.data(), doc.id);
      debugPrint(
        "✅ Parsed address: first='${address.first}', last='${address.last}', line1='${address.line1}', city='${address.city}', state='${address.state}'",
      );
      return address;
    }).toList();

    setState(() {
      addressList = addresses;

      // Check if there's a currently selected address
      if (selectedAddressService.hasSelectedAddress) {
        final currentAddress = selectedAddressService.selectedAddress!;
        final existingAddress = addresses.firstWhere(
          (addr) => addr.id == currentAddress.id,
          orElse: () => addresses.isNotEmpty
              ? addresses.first
              : Address(
                  id: '',
                  first: '',
                  last: '',
                  line1: '',
                  line2: '',
                  city: '',
                  state: '',
                  pincode: '',
                ),
        );
        selectedAddressId = existingAddress.id.isNotEmpty
            ? existingAddress.id
            : null;
      } else if (addresses.isNotEmpty) {
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

    // Save the selected address to the service
    selectedAddressService.setSelectedAddress(selected);

    debugPrint('Selected address: ${selected.line1}, ${selected.city}');

    // Navigate back to the previous page
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Address")),
      body: Column(
        children: [
          Expanded(
            child: addressList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No addresses found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please add an address to continue',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
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
                                  Text(
                                    address.line2,
                                    style: TextStyle(fontSize: 14),
                                  ),
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
                      hintText: addressList.isEmpty
                          ? 'No Address Available'
                          : 'Select This Address',
                      onPressed:
                          addressList.isEmpty || selectedAddressId == null
                          ? () {} // Empty function instead of null
                          : selectAddress,
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
