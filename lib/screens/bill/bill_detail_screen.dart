import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bill_model.dart';
import '../../providers/bill_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/websocket_service.dart';
import 'package:share_plus/share_plus.dart';

class BillDetailScreen extends StatefulWidget {
  final BillModel bill;
  const BillDetailScreen({super.key, required this.bill});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  final WebSocketService _wsService = WebSocketService();
  final List<String> _wsMessages = [];
  late BillModel _bill;

  @override
  void initState() {
    super.initState();
    _bill = widget.bill;
    _wsService.connect(_bill.id);
    _wsService.messages.listen((msg) {
      if (mounted) setState(() => _wsMessages.add(msg));
    });
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        context.read<AuthProvider>().user?.displayName ?? 'Kamu';
    final allPersons = ['Kamu', ..._bill.members];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Tagihan',
            style:
                TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
  IconButton(
    icon: const Icon(Icons.share_outlined, color: Color(0xFF7C3AED)),
    onPressed: () => _shareBill(),
  ),
  IconButton(
    icon: const Icon(Icons.delete_outline, color: Colors.red),
    onPressed: () => _confirmDelete(context),
  ),
],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.receipt_long,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(_bill.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_bill.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _bill.status == 'paid'
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _bill.status == 'paid' ? 'LUNAS' : 'BELUM LUNAS',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Ringkasan biaya
            const Text('Ringkasan Biaya',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8)
                ],
              ),
              child: Column(
                children: [
                  _summaryRow('Subtotal',
                      'Rp ${_bill.subtotal.toStringAsFixed(0)}'),
                  _summaryRow(
                      'Pajak (${_bill.taxPercent.toStringAsFixed(0)}%)',
                      'Rp ${_bill.taxAmount.toStringAsFixed(0)}',
                      color: Colors.red.shade400),
                  _summaryRow(
                      'Service (${_bill.servicePercent.toStringAsFixed(0)}%)',
                      'Rp ${_bill.serviceAmount.toStringAsFixed(0)}',
                      color: Colors.red.shade400),
                  const Divider(height: 20),
                  _summaryRow(
                    'Grand Total',
                    'Rp ${_bill.grandTotal.toStringAsFixed(0)}',
                    isBold: true,
                    color: const Color(0xFF7C3AED),
                    fontSize: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rincian per orang
            const Text('Tagihan Per Orang',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (_bill.items.isEmpty)
              // Tampilan lama jika tidak ada items
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: allPersons
                      .map((p) => _memberRow(
                            p == 'Kamu' ? userName : p,
                            _bill.grandTotal / allPersons.length,
                            _bill.status == 'paid',
                            isOwner: p == 'Kamu',
                          ))
                      .toList(),
                ),
              )
            else
              // Rincian per orang dengan item
              ...allPersons.map((person) {
                final displayName =
                    person == 'Kamu' ? userName : person;
                final personItems = _bill.items
                    .where((i) => i.orderedBy.contains(person))
                    .toList();
                if (personItems.isEmpty) return const SizedBox.shrink();

                double personSubtotal = personItems.fold(
                    0,
                    (sum, i) =>
                        sum +
                        (i.price *
                            i.qty /
                            (i.orderedBy.isEmpty
                                ? 1
                                : i.orderedBy.length)));
                final tax = personSubtotal *
                    (_bill.taxPercent / 100);
                final service = personSubtotal *
                    (_bill.servicePercent / 100);
                final total = personSubtotal + tax + service;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF7C3AED),
                            child: Text(
                              displayName[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(displayName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                Text(
                                    '${personItems.length} item pesanan',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _bill.status == 'paid'
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _bill.status == 'paid'
                                  ? 'Lunas'
                                  : 'Belum',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _bill.status == 'paid'
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      // Item pesanan
                      ...personItems.map((item) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.qty}x ${item.name}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  'Rp ${(item.price * item.qty / (item.orderedBy.isEmpty ? 1 : item.orderedBy.length)).toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          )),
                      const Divider(height: 16),
                      _summaryRow(
                          'Subtotal',
                          'Rp ${personSubtotal.toStringAsFixed(0)}',
                          isSmall: true),
                      _summaryRow(
                          'Pajak',
                          'Rp ${tax.toStringAsFixed(0)}',
                          isSmall: true,
                          color: Colors.red.shade400),
                      _summaryRow(
                          'Service',
                          'Rp ${service.toStringAsFixed(0)}',
                          isSmall: true,
                          color: Colors.red.shade400),
                      const SizedBox(height: 4),
                      _summaryRow(
                        'Total',
                        'Rp ${total.toStringAsFixed(0)}',
                        isBold: true,
                        color: const Color(0xFF7C3AED),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 24),

            // WebSocket realtime
            if (_wsMessages.isNotEmpty) ...[
              const Text('Aktivitas Realtime',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: _wsMessages
                      .map((msg) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.circle,
                                    size: 8,
                                    color: Color(0xFF7C3AED)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(msg,
                                        style: const TextStyle(
                                            fontSize: 13))),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Tombol update status
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bill.status == 'paid'
                      ? Colors.orange
                      : Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: Icon(
                  _bill.status == 'paid'
                      ? Icons.unpublished_outlined
                      : Icons.check_circle_outline,
                  color: Colors.white,
                ),
                label: Text(
                  _bill.status == 'paid'
                      ? 'Tandai Belum Lunas'
                      : 'Tandai Lunas',
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () => _toggleStatus(context),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isBold = false,
      bool isSmall = false,
      Color? color,
      double? fontSize}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize ?? (isSmall ? 12 : 14),
                  color: color ?? Colors.grey.shade700)),
          Text(value,
              style: TextStyle(
                  fontSize: fontSize ?? (isSmall ? 12 : 14),
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _memberRow(String name, double amount, bool isPaid,
      {bool isOwner = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isOwner
                ? const Color(0xFF7C3AED)
                : const Color(0xFFEDE9FE),
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(
                  color: isOwner
                      ? Colors.white
                      : const Color(0xFF7C3AED),
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  isPaid ? 'Sudah Bayar' : 'Belum Bayar',
                  style: TextStyle(
                      fontSize: 12,
                      color:
                          isPaid ? Colors.green : Colors.orange),
                ),
              ],
            ),
          ),
          Text('Rp ${amount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(BuildContext context) async {
    final newStatus = _bill.status == 'paid' ? 'unpaid' : 'paid';
    await context
        .read<BillProvider>()
        .updateBillStatus(_bill.id, newStatus);
    if (mounted) {
      setState(() {
        _bill = BillModel(
          id: _bill.id,
          title: _bill.title,
          totalAmount: _bill.totalAmount,
          createdBy: _bill.createdBy,
          members: _bill.members,
          items: _bill.items,
          taxPercent: _bill.taxPercent,
          servicePercent: _bill.servicePercent,
          status: newStatus,
          createdAt: _bill.createdAt,
        );
      });
    }
  }

 void _shareBill() {
  final allPersons = ['Kamu', ..._bill.members];
  final buffer = StringBuffer();

  buffer.writeln('🧾 *${_bill.title}*');
  buffer.writeln('━━━━━━━━━━━━━━━━━━');

  for (final person in allPersons) {
    final personItems = _bill.items
        .where((i) => i.orderedBy.contains(person))
        .toList();
    if (personItems.isEmpty) continue;

    double personSubtotal = personItems.fold(
        0, (sum, i) => sum + (i.price * i.qty));
    final tax = personSubtotal * (_bill.taxPercent / 100);
    final service = personSubtotal * (_bill.servicePercent / 100);
    final total = personSubtotal + tax + service;

    buffer.writeln('\n👤 *$person*');
    for (final item in personItems) {
      buffer.writeln('  • ${item.qty}x ${item.name} = Rp ${(item.price * item.qty).toStringAsFixed(0)}');
    }
    buffer.writeln('  Subtotal: Rp ${personSubtotal.toStringAsFixed(0)}');
    buffer.writeln('  Pajak: Rp ${tax.toStringAsFixed(0)}');
    buffer.writeln('  Service: Rp ${service.toStringAsFixed(0)}');
    buffer.writeln('  *Total: Rp ${total.toStringAsFixed(0)}*');
  }

  buffer.writeln('\n━━━━━━━━━━━━━━━━━━');
  buffer.writeln('💰 *Grand Total: Rp ${_bill.grandTotal.toStringAsFixed(0)}*');
  buffer.writeln('Status: ${_bill.status == 'paid' ? '✅ LUNAS' : '⏳ BELUM LUNAS'}');
  buffer.writeln('\nDikirim via SplitMate 🚀');

  Share.share(buffer.toString(), subject: _bill.title);
}
  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tagihan?'),
        content: const Text('Tagihan ini akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<BillProvider>().deleteBill(_bill.id);
      Navigator.pop(context);
    }
  }
}