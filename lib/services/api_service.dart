import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
 static const String baseUrl = 'http://10.27.110.234/splitmate-server';

  // Register user ke MySQL
  static Future<bool> registerUser(String uid, String name, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'name': name, 'email': email}),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('registerUser error: $e');
      return false;
    }
  }

  // Simpan FCM token
  static Future<bool> registerToken(String uid, String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register_token.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'fcm_token': fcmToken}),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('registerToken error: $e');
      return false;
    }
  }

  // Ambil bills
  static Future<List<dynamic>> getBills(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bills/read.php?user_id=$userId'),
      );
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } catch (e) {
      print('getBills error: $e');
      return [];
    }
  }

  // Buat bill baru
  static Future<bool> createBill(Map<String, dynamic> billData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bills/create.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(billData),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('createBill error: $e');
      return false;
    }
  }

  // Update status bill
  static Future<bool> updateBillStatus(String billId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bills/update.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': billId, 'status': status}),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('updateBillStatus error: $e');
      return false;
    }
  }

  // Hapus bill
  static Future<bool> deleteBill(String billId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bills/delete.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': billId}),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('deleteBill error: $e');
      return false;
    }
  }
}