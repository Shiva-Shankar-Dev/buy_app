import 'package:buy_app/services/addresses.dart';

class SelectedAddressService {
  static final SelectedAddressService _instance =
      SelectedAddressService._internal();
  factory SelectedAddressService() => _instance;
  SelectedAddressService._internal();

  static SelectedAddressService get instance => _instance;

  Address? _selectedAddress;

  Address? get selectedAddress => _selectedAddress;

  bool get hasSelectedAddress => _selectedAddress != null;

  void setSelectedAddress(Address address) {
    _selectedAddress = address;
  }

  void clearSelectedAddress() {
    _selectedAddress = null;
  }

  String getDisplayText() {
    if (_selectedAddress == null) {
      return 'Select Delivery Address';
    }

    final address = _selectedAddress!;
    final name = '${address.first} ${address.last}'.trim();
    final location = '${address.city}, ${address.state}'.trim();

    if (name.isEmpty) {
      return location.isEmpty ? 'Selected Address' : location;
    }

    return '$name - $location';
  }

  String getFullAddressText() {
    if (_selectedAddress == null) {
      return 'No address selected';
    }

    final address = _selectedAddress!;
    final parts = <String>[];

    if (address.first.isNotEmpty || address.last.isNotEmpty) {
      parts.add('${address.first} ${address.last}'.trim());
    }

    if (address.line1.isNotEmpty) {
      parts.add(address.line1);
    }

    if (address.line2.isNotEmpty) {
      parts.add(address.line2);
    }

    if (address.city.isNotEmpty ||
        address.state.isNotEmpty ||
        address.pincode.isNotEmpty) {
      parts.add('${address.city}, ${address.state} - ${address.pincode}');
    }

    return parts.join('\n');
  }
}
