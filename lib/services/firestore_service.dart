import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bill_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((d) => UserModel.fromMap(d.data())).toList();
  }

  Future<void> createBill(BillModel bill) async {
    await _db.collection('bills').doc(bill.id).set(bill.toMap());
  }

  Stream<List<BillModel>> getBillsByUser(String userId) {
    return _db
        .collection('bills')
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BillModel.fromMap(d.data())).toList());
  }

  Future<void> updateBill(String billId, Map<String, dynamic> data) async {
    await _db.collection('bills').doc(billId).update(data);
  }

  Future<void> deleteBill(String billId) async {
    await _db.collection('bills').doc(billId).delete();
  }

  Future<void> updateFcmToken(String uid, String token) async {
  await _db.collection('users').doc(uid).set(
    {'fcmToken': token},
    SetOptions(merge: true), // pakai merge agar tidak overwrite data lain
  );
}

  Future<void> sendNotification(NotificationModel notif) async {
    await _db.collection('notifications').doc(notif.id).set(notif.toMap());
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => NotificationModel.fromMap(d.data()))
            .toList());
  }

  Future<void> markNotificationRead(String notifId) async {
    await _db
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }
}