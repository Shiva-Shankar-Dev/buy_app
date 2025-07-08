class Address {
  final String id;
  final String line1;
  final String line2;
  final String cityState;
  final String pincode;

  Address({
    required this.id,
    required this.line1,
    required this.line2,
    required this.cityState,
    required this.pincode,
  });

  factory Address.fromMap(Map<String, dynamic> map, String id) {
    return Address(
      id: id,
      line1: map['line1'] ?? '',
      line2: map['line2'] ?? '',
      cityState: map['cityState'] ?? '',
      pincode: map['pincode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'line1': line1,
      'line2': line2,
      'cityState': cityState,
      'pincode': pincode,
    };
  }
}
