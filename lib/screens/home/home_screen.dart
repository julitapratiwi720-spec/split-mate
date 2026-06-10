import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/bill_model.dart';
import '../bill/bill_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      context.read<BillProvider>().loadBills(auth.user!.uid);
      context.read<NotificationProvider>().listenNotifications(auth.user!.uid);
    }
  });
}

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final billProvider = context.watch<BillProvider>();
    final name = auth.user?.displayName ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back,',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600)),
                      const Text('SplitMate',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED))),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/activity'),
                      ),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF7C3AED),
                        radius: 18,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Total Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Balance',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      'Rp ${_totalAmount(billProvider.bills)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _balanceChip(
                            '↓ Owed to you',
                            'Rp ${_owedToYou(billProvider.bills)}',
                            Colors.green.shade300),
                        const SizedBox(width: 16),
                        _balanceChip(
                            '↑ You owe',
                            'Rp ${_youOwe(billProvider.bills)}',
                            Colors.red.shade300),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Aktivitas Terkini
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Aktivitas Terkini',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/activity'),
                    child: const Text('See All',
                        style: TextStyle(color: Color(0xFF7C3AED))),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Bill List
              billProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : billProvider.bills.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: billProvider.bills.length,
                          itemBuilder: (context, i) =>
                              _billCard(billProvider.bills[i]),
                        ),
            ],
          ),
        ),
      ),

      // FAB
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7C3AED),
        onPressed: () => Navigator.pushNamed(context, '/create-bill'),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      // Bottom Nav
      bottomNavigationBar: Consumer<NotificationProvider>(
        builder: (context, notifProvider, _) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: const Color(0xFF7C3AED),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            onTap: (i) {
              setState(() => _currentIndex = i);
              if (i == 1) Navigator.pushNamed(context, '/create-bill');
              if (i == 2) Navigator.pushNamed(context, '/activity');
              if (i == 3) Navigator.pushNamed(context, '/profile');
            },
            items: [
              const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined), label: 'Home'),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline), label: 'Buat'),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: notifProvider.unreadCount > 0,
                  label: Text('${notifProvider.unreadCount}'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                label: 'Activity',
              ),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
          );
        },
      ),
    );
  }

  Widget _balanceChip(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(amount,
            style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _billCard(BillModel bill) {
    final isPaid = bill.status == 'paid';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BillDetailScreen(bill: bill),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_outlined,
                  color: Color(0xFF7C3AED)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    bill.createdAt.toString().substring(0, 10),
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp ${bill.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPaid ? 'SETTLED' : 'PENDING',
                    style: TextStyle(
                        fontSize: 10,
                        color: isPaid
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Belum ada tagihan',
              style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text('Tap + untuk buat tagihan baru',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  String _totalAmount(List<BillModel> bills) {
    final total = bills.fold(0.0, (sum, b) => sum + b.totalAmount);
    return total.toStringAsFixed(0);
  }

  String _owedToYou(List<BillModel> bills) {
    final total = bills
        .where((b) => b.status == 'unpaid')
        .fold(0.0, (sum, b) => sum + b.totalAmount / 2);
    return total.toStringAsFixed(0);
  }

  String _youOwe(List<BillModel> bills) {
    final total = bills
        .where((b) => b.status == 'paid')
        .fold(0.0, (sum, b) => sum + b.totalAmount / 2);
    return total.toStringAsFixed(0);
  }
}