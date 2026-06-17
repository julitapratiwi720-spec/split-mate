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

  BillProvider() {
    debugPrint('🔥 BillProvider initialized');
    _wsService.connect('global_room');
  }

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
    _errorMessage = null;
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

      debugPrint('📝 Menyimpan ke Firestore...');
      await _firestoreService.createBill(bill);

      debugPrint('📝 Menyimpan ke MySQL...');
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

      debugPrint('🔔 Membuat notifikasi...');

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

      debugPrint('📢 Mengirim event websocket...');
      _wsService.sendMessage('Bill baru: $title');

      return true;
    } catch (e, s) {
      debugPrint('❌ CREATE BILL ERROR');
      debugPrint(e.toString());
      debugPrint(s.toString());

      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBillStatus(
    String billId,
    String status,
  ) async {
    await _firestoreService.updateBill(
      billId,
      {'status': status},
    );

    await ApiService.updateBillStatus(
      billId,
      status,
    );
  }

  Future<void> deleteBill(String billId) async {
    await _firestoreService.deleteBill(billId);

    await ApiService.deleteBill(billId);
  }

  void connectWebSocket(String billId) {
    _wsService.connect(billId);
  }

  void disconnectWebSocket() {
    _wsService.disconnect();
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }
}