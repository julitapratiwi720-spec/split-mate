import 'package:flutter/material.dart';
import '../models/bill_model.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart';
import 'package:uuid/uuid.dart';

class BillProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final WebSocketService _wsService = WebSocketService();

  List<BillModel> _bills = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BillModel> get bills => _bills;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Stream<String> get wsMessages => _wsService.messages;

  void loadBills(String userId) {
    _isLoading = true;
    notifyListeners();
    _firestoreService.getBillsByUser(userId).listen((bills) {
      _bills = bills;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> createBill({
    required String title,
    required double totalAmount,
    required String createdBy,
    required String createdByName,
    required List<String> members,
    required List<String> memberIds,
    List<BillItemModel> items = const [],
    double taxPercent = 0,
    double servicePercent = 0,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final billId = const Uuid().v4();
      final bill = BillModel(
        id: billId,
        title: title,
        totalAmount: totalAmount,
        createdBy: createdBy,
        members: members,
        items: items,
        taxPercent: taxPercent,
        servicePercent: servicePercent,
        createdAt: DateTime.now(),
      );

      // Simpan ke Firestore
      await _firestoreService.createBill(bill);

      // Simpan ke MySQL + kirim FCM via PHP
      await ApiService.createBill({
        'id': billId,
        'title': title,
        'total_amount': totalAmount,
        'created_by': createdBy,
        'created_by_name': createdByName,
        'members': members,
        'items': items.map((i) => i.toMap()).toList(),
        'tax_percent': taxPercent,
        'service_percent': servicePercent,
      });

      // Kirim notifikasi Firestore ke semua user kecuali pembuat
      final allUsers = await _firestoreService.getAllUsers();
      for (final user in allUsers) {
        if (user.uid != createdBy) {
          final notif = NotificationModel(
            id: const Uuid().v4(),
            toUserId: user.uid,
            title: 'Tagihan Baru! 🧾',
            body: '$createdByName menambahkan tagihan "$title"',
            createdAt: DateTime.now(),
          );
          await _firestoreService.sendNotification(notif);
        }
      }

      _wsService.sendMessage('Bill baru: $title');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBillStatus(String billId, String status) async {
    // Update di Firestore
    await _firestoreService.updateBill(billId, {'status': status});
    // Update di MySQL
    await ApiService.updateBillStatus(billId, status);
  }

  Future<void> deleteBill(String billId) async {
    // Hapus di Firestore
    await _firestoreService.deleteBill(billId);
    // Hapus di MySQL
    await ApiService.deleteBill(billId);
  }

  void connectWebSocket(String billId) => _wsService.connect(billId);
  void disconnectWebSocket() => _wsService.disconnect();

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }
}