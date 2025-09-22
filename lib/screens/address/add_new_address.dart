import 'package:buy_app/services/addresses.dart';
import 'package:buy_app/widgets/auth_text_field.dart';
import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddNewAddressPage extends StatefulWidget {
  final Address? existingAddress;
  final bool isEditing;

  const AddNewAddressPage({
    super.key,
    this.existingAddress,
    this.isEditing = false,
  });

  @override
  State<AddNewAddressPage> createState() => _AddNewAddressPageState();
}

class _AddNewAddressPageState extends State<AddNewAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final first = TextEditingController();
  final last = TextEditingController();
  final line1 = TextEditingController();
  final line2 = TextEditingController();
  final city = TextEditingController();
  final pincode = TextEditingController();
  final state = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAddress != null) {
      // Pre-fill form if editing
      first.text = widget.existingAddress!.first;
      last.text = widget.existingAddress!.last;
      line1.text = widget.existingAddress!.line1;
      line2.text = widget.existingAddress!.line2;
      city.text = widget.existingAddress!.city;
      state.text = widget.existingAddress!.state;
      pincode.text = widget.existingAddress!.pincode;
    }
  }

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    line1.dispose();
    line2.dispose();
    city.dispose();
    pincode.dispose();
    state.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (first.text.trim().isEmpty) {
      _showError('Please enter first name');
      return false;
    }
    if (last.text.trim().isEmpty) {
      _showError('Please enter last name');
      return false;
    }
    if (line1.text.trim().isEmpty) {
      _showError('Please enter address line 1');
      return false;
    }
    if (city.text.trim().isEmpty) {
      _showError('Please enter city');
      return false;
    }
    if (state.text.trim().isEmpty) {
      _showError('Please enter state');
      return false;
    }
    if (pincode.text.trim().isEmpty) {
      _showError('Please enter pincode');
      return false;
    }
    if (pincode.text.trim().length != 6) {
      _showError('Pincode must be 6 digits');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void saveAddress() async {
    if (!_validateForm()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showError('User not logged in');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final address = Address(
      id: widget.existingAddress?.id ?? '', // Use existing ID if editing
      first: first.text.trim(),
      last: last.text.trim(),
      line1: line1.text.trim(),
      line2: line2.text.trim(),
      city: city.text.trim(),
      state: state.text.trim(),
      pincode: pincode.text.trim(),
    );

    bool success;
    if (widget.isEditing && widget.existingAddress != null) {
      success = await AddressService.updateAddressWithUID(
        uid,
        widget.existingAddress!.id,
        address,
      );
    } else {
      success = await AddressService.saveAddressWithUID(uid, address);
    }

    setState(() {
      isLoading = false;
    });

    if (success) {
      Navigator.pop(context, true); // Return true to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Address updated successfully!'
                : 'Address saved successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showError('Failed to save address');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? "Edit Address" : "Add Address"),
        backgroundColor: colorPallete.color1,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      AuthTextField(hintText: "First Name", controller: first),
                      SizedBox(height: 16),
                      AuthTextField(hintText: "Last Name", controller: last),
                      SizedBox(height: 16),
                      AuthTextField(
                        hintText: "Address Line 1",
                        controller: line1,
                      ),
                      SizedBox(height: 16),
                      AuthTextField(
                        hintText: "Address Line 2 (Optional)",
                        controller: line2,
                      ),
                      SizedBox(height: 16),
                      AuthTextField(hintText: "City", controller: city),
                      SizedBox(height: 16),
                      AuthTextField(hintText: "State", controller: state),
                      SizedBox(height: 16),
                      AuthTextField(hintText: "Pincode", controller: pincode),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPallete.color1,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.isEditing ? "Update Address" : "Save Address",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
