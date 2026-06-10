import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      context
          .read<NotificationProvider>()
          .listenNotifications(auth.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Notifikasi',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          if (notifProvider.notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                for (final n in notifProvider.notifications) {
                  await notifProvider.markAsRead(n.id);
                }
              },
              child: const Text('Tandai semua dibaca',
                  style: TextStyle(
                      color: Color(0xFF7C3AED), fontSize: 12)),
            ),
        ],
      ),
      body: notifProvider.notifications.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifProvider.notifications.length,
              itemBuilder: (context, i) {
                final notif = notifProvider.notifications[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8)
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Color(0xFF7C3AED)),
                    ),
                    title: Text(notif.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notif.body,
                            style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          notif.createdAt.toString().substring(0, 16),
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.check_circle_outline,
                          color: Color(0xFF7C3AED)),
                      onPressed: () => notifProvider.markAsRead(notif.id),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.notifications_off_outlined,
                size: 40, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 16),
          const Text('Tidak ada notifikasi',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Notifikasi tagihan baru akan muncul di sini',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}