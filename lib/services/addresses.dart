class Address {
  final String id;
  final String line1;
  final String line2;
  final String city;
  final String pincode;
  final String first;
  final String last;
  final String state;
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

  factory Address.fromMap(Map<String, dynamic> map, String id) {
    return Address(
      id: id,
      first: map['first'] ?? '',
      last: map['last'] ?? '',
      line1: map['line1'] ?? '',
      line2: map['line2'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
    );
  }

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
}
