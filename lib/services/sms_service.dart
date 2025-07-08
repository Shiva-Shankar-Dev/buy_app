import 'package:http/http.dart' as http;

Future<void> sendSMS(String phoneNumber, String message) async {
  const apiKey =
      'jQnNqjFz0kMdaapBL4VubelaYhp2XOm6iwI6wOVQLNq4lhdIITpbdHXxIrLj'; // Replace with your actual API key

  final url = Uri.parse('https://www.fast2sms.com/dev/bulkV2');

  final response = await http.post(
    url,
    headers: {
      'authorization': apiKey,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'route': 'v3',
      'sender_id': 'FSTSMS',
      'message': message,
      'language': 'english',
      'flash': '0',
      'numbers': phoneNumber,
    },
  );

  print('🔁 Response code: ${response.statusCode}');
  print('📦 Response body: ${response.body}');

  if (response.statusCode == 200 && response.body.contains('"return":true')) {
    print('✅ SMS sent successfully!');
  } else {
    print('❌ Failed to send SMS: ${response.body}');
  }
}
