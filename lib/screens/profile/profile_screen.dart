import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bill_provider.dart';
import '../../models/bill_model.dart';
import '../bill/bill_detail_screen.dart';
import '../../widgets/notification_overlay.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.displayName ?? 'User';
    final email = auth.user?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profil',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF7C3AED),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style:
                    const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            Text(email,
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),

            // Stats card
            Consumer<BillProvider>(
              builder: (context, billProvider, _) {
                final bills = billProvider.bills;
                final paid =
                    bills.where((b) => b.status == 'paid').length;
                final unpaid =
                    bills.where((b) => b.status != 'paid').length;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('Total Tagihan', '${bills.length}',
                          Colors.white),
                      _divider(),
                      _statItem('Lunas', '$paid',
                          Colors.green.shade300),
                      _divider(),
                      _statItem('Belum Lunas', '$unpaid',
                          Colors.orange.shade300),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Menu items
            _menuItem(
              Icons.receipt_outlined,
              'Riwayat Tagihan',
              () => _showRiwayat(context),
            ),
            _menuItem(Icons.notifications_outlined, 'Notifikasi', () {}),
            _menuItem(Icons.notifications_active_outlined, 'Test Notifikasi', () {
              NotificationOverlay.of(context)?.showNotification('SplitMate 🔔','Tagihan baru menunggumu!',
              );
            }),
            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Keluar',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRiwayat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RiwayatSheet(),
    );
  }

  Widget _statItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _divider() {
    return Container(
        width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3));
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF7C3AED)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _RiwayatSheet extends StatefulWidget {
  const _RiwayatSheet();

  @override
  State<_RiwayatSheet> createState() => _RiwayatSheetState();
}

class _RiwayatSheetState extends State<_RiwayatSheet> {
  String _filter = 'semua'; // semua, lunas, belum

  @override
  Widget build(BuildContext context) {
    final bills = context.watch<BillProvider>().bills;

    final filtered = bills.where((b) {
      if (_filter == 'lunas') return b.status == 'paid';
      if (_filter == 'belum') return b.status != 'paid';
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F7FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Riwayat Tagihan',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Filter chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _filterChip('semua', 'Semua'),
                const SizedBox(width: 8),
                _filterChip('lunas', 'Lunas'),
                const SizedBox(width: 8),
                _filterChip('belum', 'Belum Lunas'),
              ],
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 56,
                              color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('Tidak ada tagihan',
                              style: TextStyle(
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) =>
                          _riwayatCard(filtered[i], context),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C3AED)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 13),
        ),
      ),
    );
  }

  Widget _riwayatCard(BillModel bill, BuildContext context) {
    final isPaid = bill.status == 'paid';
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => BillDetailScreen(bill: bill)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6)
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isPaid
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPaid
                    ? Icons.check_circle_outline
                    : Icons.pending_outlined,
                color:
                    isPaid ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                  Text(
                    bill.createdAt.toString().substring(0, 10),
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp ${bill.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  isPaid ? 'Lunas' : 'Belum Lunas',
                  style: TextStyle(
                      fontSize: 11,
                      color: isPaid
                          ? Colors.green
                          : Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}