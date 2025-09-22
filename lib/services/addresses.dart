import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String first, last, line1, line2, city, state, pincode;

  Address({
    required this.id,
    required this.first,
    required this.last,
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.pincode,
  });

  // Convert Address to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'first': first,
      'last': last,
      'line1': line1,
      'line2': line2,
      'city': city,
      'state': state,
      'pincode': pincode,
    };
  }

  // Create Address from Firestore Map with document ID
  factory Address.fromMap(Map<String, dynamic> map, String docId) {
    return Address(
      id: docId,
      first: map['first'] ?? '',
      last: map['last'] ?? '',
      line1: map['line1'] ?? '',
      line2: map['line2'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
    );
  }

  // Create Address from Firestore Map without document ID (for backwards compatibility)
  factory Address.fromMapLegacy(Map<String, dynamic> map) {
    return Address(
      id: '', // Empty ID for legacy support
      first: map['first'] ?? '',
      last: map['last'] ?? '',
      line1: map['line1'] ?? '',
      line2: map['line2'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
    );
  }

  @override
  String toString() {
    return '$first $last, $line1, ${line2.isNotEmpty ? '$line2, ' : ''}$city, $state - $pincode';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        other.first == first &&
        other.last == last &&
        other.line1 == line1 &&
        other.line2 == line2 &&
        other.city == city &&
        other.state == state &&
        other.pincode == pincode;
  }

  @override
  int get hashCode {
    return first.hashCode ^
        last.hashCode ^
        line1.hashCode ^
        line2.hashCode ^
        city.hashCode ^
        state.hashCode ^
        pincode.hashCode;
  }
}

class AddressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save address using UID (recommended approach)
  static Future<bool> saveAddressWithUID(String uid, Address address) async {
    try {
      await _firestore
          .collection('customers')
          .doc(uid)
          .collection('addresses')
          .add(address.toMap());

      print('✅ Address saved successfully with UID');
      return true;
    } catch (e) {
      print('❌ Error saving address with UID: $e');
      return false;
    }
  }

  /// Get addresses using UID
  static Future<List<Address>> getAddressesWithUID(String uid) async {
    try {
      final querySnapshot = await _firestore
          .collection('customers')
          .doc(uid)
          .collection('addresses')
          .get();

      return querySnapshot.docs
          .map((doc) => Address.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error fetching addresses with UID: $e');
      return [];
    }
  }

  /// Delete address using UID and document ID
  static Future<bool> deleteAddressWithUID(String uid, String addressId) async {
    try {
      await _firestore
          .collection('customers')
          .doc(uid)
          .collection('addresses')
          .doc(addressId)
          .delete();

      print('✅ Address deleted successfully with UID');
      return true;
    } catch (e) {
      print('❌ Error deleting address with UID: $e');
      return false;
    }
  }

  /// Update address using UID and document ID
  static Future<bool> updateAddressWithUID(
    String uid,
    String addressId,
    Address address,
  ) async {
    try {
      await _firestore
          .collection('customers')
          .doc(uid)
          .collection('addresses')
          .doc(addressId)
          .update(address.toMap());

      print('✅ Address updated successfully with UID');
      return true;
    } catch (e) {
      print('❌ Error updating address with UID: $e');
      return false;
    }
  }

  // Legacy methods for email-based approach (for backwards compatibility)

  /// Save address using email (legacy)
  static Future<bool> saveAddress(String userEmail, Address address) async {
    try {
      final addressHash =
          '${address.first}_${address.last}_${address.line1}_${address.city}_${address.pincode}'
              .replaceAll(' ', '_');

      await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('addresses')
          .doc(addressHash)
          .set(address.toMap());

      print('✅ Address saved successfully with email');
      return true;
    } catch (e) {
      print('❌ Error saving address with email: $e');
      return false;
    }
  }

  /// Get addresses using email (legacy)
  static Future<List<Address>> getAddresses(String userEmail) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('addresses')
          .get();

      return querySnapshot.docs
          .map((doc) => Address.fromMapLegacy(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error fetching addresses with email: $e');
      return [];
    }
  }

  /// Delete address using email (legacy)
  static Future<bool> deleteAddress(String userEmail, Address address) async {
    try {
      final addressHash =
          '${address.first}_${address.last}_${address.line1}_${address.city}_${address.pincode}'
              .replaceAll(' ', '_');

      await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('addresses')
          .doc(addressHash)
          .delete();

      print('✅ Address deleted successfully with email');
      return true;
    } catch (e) {
      print('❌ Error deleting address with email: $e');
      return false;
    }
  }

  /// Update address using email (legacy)
  static Future<bool> updateAddress(
    String userEmail,
    Address oldAddress,
    Address newAddress,
  ) async {
    try {
      final deleteSuccess = await deleteAddress(userEmail, oldAddress);
      if (deleteSuccess) {
        return await saveAddress(userEmail, newAddress);
      }
      return false;
    } catch (e) {
      print('❌ Error updating address with email: $e');
      return false;
    }
  }
}
