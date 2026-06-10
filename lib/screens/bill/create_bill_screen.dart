import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bill_provider.dart';
import '../../models/bill_model.dart';

class CreateBillScreen extends StatefulWidget {
  const CreateBillScreen({super.key});

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  final _titleController = TextEditingController();
  final _memberController = TextEditingController();
  final _taxController = TextEditingController(text: '10');
  final _serviceController = TextEditingController(text: '5');
  final List<String> _members = [];
  final List<BillItemModel> _items = [];
  int _currentStep = 0;

  final _itemNameController = TextEditingController();
  final _itemPriceController = TextEditingController();
  // Map: nama orang -> jumlah porsi (0 = tidak pesan)
  Map<String, int> _personQty = {};

  void _addMember() {
    final name = _memberController.text.trim();
    if (name.isNotEmpty && !_members.contains(name)) {
      setState(() => _members.add(name));
      _memberController.clear();
    }
  }

  void _addItem() {
    if (_itemNameController.text.isEmpty || _itemPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan harga item wajib diisi')),
      );
      return;
    }
    // Hanya orang yang qty-nya > 0
    final ordered = _personQty.entries
        .where((e) => e.value > 0)
        .toList();

    if (ordered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 orang yang memesan')),
      );
      return;
    }

    final double hargaSatuan =
        double.tryParse(_itemPriceController.text) ?? 0;

    // Buat 1 BillItemModel per orang dengan qty masing-masing
    setState(() {
      for (final entry in ordered) {
        _items.add(BillItemModel(
          name: _itemNameController.text.trim(),
          price: hargaSatuan,
          qty: entry.value,
          orderedBy: [entry.key],
        ));
      }
      _itemNameController.clear();
      _itemPriceController.clear();
      _personQty = {};
    });
  }

  double get _subtotal =>
      _items.fold(0, (sum, i) => sum + (i.price * i.qty));

  double get _taxAmount =>
      _subtotal * ((double.tryParse(_taxController.text) ?? 0) / 100);

  double get _serviceAmount =>
      _subtotal * ((double.tryParse(_serviceController.text) ?? 0) / 100);

  double get _grandTotal => _subtotal + _taxAmount + _serviceAmount;

  Future<void> _createBill() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tagihan wajib diisi')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final billProvider = context.read<BillProvider>();
    final success = await billProvider.createBill(
      title: _titleController.text.trim(),
      totalAmount: _grandTotal,
      createdBy: auth.user!.uid,
      createdByName: auth.user!.displayName ?? 'User',
      members: _members,
      memberIds: const [],
      items: _items,
      taxPercent: double.tryParse(_taxController.text) ?? 0,
      servicePercent: double.tryParse(_serviceController.text) ?? 0,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tagihan berhasil dibuat!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Buat Tagihan',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isActive || isDone
                      ? const Color(0xFF7C3AED)
                      : Colors.grey.shade300,
                  child: Text('${i + 1}',
                      style: TextStyle(
                          color: isActive || isDone ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone
                          ? const Color(0xFF7C3AED)
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Who\'s splitting?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Masukkan judul dan tambahkan anggota',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: _inputDecoration(
                'Judul tagihan (cth: Makan Bareng)', Icons.receipt_outlined),
          ),
          const SizedBox(height: 20),
          const Text('Tambah Anggota',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _memberController,
                  decoration:
                      _inputDecoration('Nama teman', Icons.person_add_outlined),
                  onSubmitted: (_) => _addMember(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: _addMember,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_members.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _members
                  .map((m) => Chip(
                        label: Text(m),
                        backgroundColor: const Color(0xFFEDE9FE),
                        labelStyle: const TextStyle(color: Color(0xFF7C3AED)),
                        deleteIconColor: const Color(0xFF7C3AED),
                        onDeleted: () => setState(() => _members.remove(m)),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pajak (%)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _taxController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('10', Icons.percent),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Service (%)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _serviceController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                          '5', Icons.room_service_outlined),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final allPersons = ['Kamu', ..._members];

    // Inisialisasi _personQty kalau belum ada entri untuk orang baru
    for (final p in allPersons) {
      _personQty.putIfAbsent(p, () => 0);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Input Pesanan',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Atur berapa porsi tiap orang memesan',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _itemNameController,
                  decoration:
                      _inputDecoration('Nama menu', Icons.restaurant_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _itemPriceController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Harga per porsi', Icons.money),
                ),
                const SizedBox(height: 16),
                const Text('Porsi per orang:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                // Setiap orang punya row sendiri dengan tombol +/-
                ...allPersons.map((p) {
                  final qty = _personQty[p] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: qty > 0
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFFEDE9FE),
                          child: Text(
                            p[0].toUpperCase(),
                            style: TextStyle(
                                color: qty > 0
                                    ? Colors.white
                                    : const Color(0xFF7C3AED),
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Nama
                        Expanded(
                          child: Text(p,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500)),
                        ),
                        // Tombol -
                        GestureDetector(
                          onTap: () {
                            if (qty > 0) {
                              setState(() => _personQty[p] = qty - 1);
                            }
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: qty > 0
                                  ? const Color(0xFFEDE9FE)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.remove,
                                size: 16,
                                color: qty > 0
                                    ? const Color(0xFF7C3AED)
                                    : Colors.grey),
                          ),
                        ),
                        // Angka qty
                        Container(
                          width: 36,
                          alignment: Alignment.center,
                          child: Text(
                            '$qty',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: qty > 0
                                    ? const Color(0xFF7C3AED)
                                    : Colors.grey),
                          ),
                        ),
                        // Tombol +
                        GestureDetector(
                          onTap: () {
                            setState(() => _personQty[p] = qty + 1);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Tambah Item',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Daftar item yang sudah ditambah
          if (_items.isNotEmpty) ...[
            const Text('Daftar Pesanan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Group item berdasarkan nama menu untuk tampilan lebih rapi
            ..._items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${item.qty}x',
                          style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text(
                            'Oleh: ${item.orderedBy.join(', ')}',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rp ${(item.price * item.qty).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 18),
                      onPressed: () =>
                          setState(() => _items.removeAt(i)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final allPersons = ['Kamu', ..._members];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rincian Pembayaran',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Pastikan semua sudah benar',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL TAGIHAN',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(
                  'Rp ${_grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_titleController.text,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Rincian Per Orang',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...allPersons.map((person) {
            final personItems =
                _items.where((i) => i.orderedBy.contains(person)).toList();
            if (personItems.isEmpty) return const SizedBox.shrink();

            // Karena orderedBy sudah 1 orang, tidak perlu dibagi
            double personSubtotal =
                personItems.fold(0, (sum, i) => sum + (i.price * i.qty));
            final tax = personSubtotal *
                ((double.tryParse(_taxController.text) ?? 0) / 100);
            final service = personSubtotal *
                ((double.tryParse(_serviceController.text) ?? 0) / 100);
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
                        child: Text(person[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(person,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text('${personItems.length} item pesanan',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ...personItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.qty}x ${item.name}',
                                style: const TextStyle(fontSize: 13)),
                            Text(
                              'Rp ${(item.price * item.qty).toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 16),
                  _summaryRow('Subtotal',
                      'Rp ${personSubtotal.toStringAsFixed(0)}',
                      isSmall: true),
                  _summaryRow(
                      'Pajak (${_taxController.text}%)',
                      'Rp ${tax.toStringAsFixed(0)}',
                      isSmall: true,
                      color: Colors.red.shade400),
                  _summaryRow(
                      'Service (${_serviceController.text}%)',
                      'Rp ${service.toStringAsFixed(0)}',
                      isSmall: true,
                      color: Colors.red.shade400),
                  const SizedBox(height: 4),
                  _summaryRow('Total Per Orang',
                      'Rp ${total.toStringAsFixed(0)}',
                      isBold: true,
                      color: const Color(0xFF7C3AED)),
                ],
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('RINGKASAN AKHIR',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontSize: 12)),
                const SizedBox(height: 12),
                _summaryRow(
                    'Total Subtotal', 'Rp ${_subtotal.toStringAsFixed(0)}'),
                _summaryRow(
                    'Total Pajak', 'Rp ${_taxAmount.toStringAsFixed(0)}'),
                _summaryRow(
                    'Total Service', 'Rp ${_serviceAmount.toStringAsFixed(0)}'),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'Rp ${_grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF7C3AED)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isBold = false, bool isSmall = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isSmall ? 12 : 14,
                  color: color ?? Colors.grey.shade700)),
          Text(value,
              style: TextStyle(
                  fontSize: isSmall ? 12 : 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    final billProvider = context.watch<BillProvider>();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => setState(() => _currentStep--),
                child: const Text('Kembali',
                    style: TextStyle(color: Color(0xFF7C3AED))),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: billProvider.isLoading
                  ? null
                  : () {
                      if (_currentStep < 2) {
                        if (_currentStep == 0 &&
                            _titleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Judul tagihan wajib diisi')),
                          );
                          return;
                        }
                        setState(() => _currentStep++);
                      } else {
                        _createBill();
                      }
                    },
              child: billProvider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _currentStep < 2 ? 'Lanjut →' : 'Kirim Tagihan',
                      style: const TextStyle(
                          fontSize: 16, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF7C3AED)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}