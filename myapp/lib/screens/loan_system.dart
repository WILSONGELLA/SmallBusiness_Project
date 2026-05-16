import 'package:flutter/material.dart';
import '../models/app_state.dart';

class ReceivablesScreen extends StatefulWidget {
  const ReceivablesScreen({super.key});

  @override
  State<ReceivablesScreen> createState() => _ReceivablesScreenState();
}

class _ReceivablesScreenState extends State<ReceivablesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<Receivable> get _unpaid => AppStore.instance.receivables
      .where((r) =>
          !r.isPaid &&
          (r.customerName.toLowerCase().contains(_search.toLowerCase()) ||
              r.customerPhone.contains(_search)))
      .toList();

  List<Receivable> get _paid => AppStore.instance.receivables
      .where((r) =>
          r.isPaid &&
          (r.customerName.toLowerCase().contains(_search.toLowerCase()) ||
              r.customerPhone.contains(_search)))
      .toList();

  void _showAddDialog() {
    final customers = AppStore.instance.customers;
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '⚠️ No customers yet. Add a customer first before creating a receivable.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFF57C00),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ReceivableFormSheet(
        onSaved: (r) {
          AppStore.instance.addReceivable(r);
          setState(() {});
          _showSnack('✅ Receivable added for ${r.customerName}');
        },
      ),
    );
  }

  void _showDetailDialog(Receivable r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      const Color(0xFFE8572A).withOpacity(0.12),
                  child: Text(r.customerName[0],
                      style: const TextStyle(
                          color: Color(0xFFE8572A),
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.customerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (r.customerPhone.isNotEmpty)
                        Text(r.customerPhone,
                            style: const TextStyle(
                                color: Color(0xFF888888), fontSize: 12)),
                    ],
                  ),
                ),
                if (!r.isPaid)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFE53935)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDelete(r);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            _detailRow('Amount', '₱${r.amount.toStringAsFixed(2)}',
                const Color(0xFFE8572A),
                bold: true),
            const SizedBox(height: 8),
            _detailRow('Date', _formatDate(r.dateCreated),
                const Color(0xFF1A1A2E)),
            if (r.dueDate != null) ...[
              const SizedBox(height: 8),
              _detailRow(
                'Due Date',
                _formatDate(r.dueDate!),
                r.isOverdue
                    ? const Color(0xFFE53935)
                    : r.isDueSoon
                        ? const Color(0xFFF57C00)
                        : const Color(0xFF1A1A2E),
              ),
            ],
            if (r.itemsSummary.isNotEmpty) ...[
              const SizedBox(height: 8),
              _detailRow('Items', r.itemsSummary.join(', '),
                  const Color(0xFF555555)),
            ],
            if (r.notes != null) ...[
              const SizedBox(height: 8),
              _detailRow('Notes', r.notes!, const Color(0xFF555555)),
            ],
            const SizedBox(height: 8),
            _detailRow(
              'Status',
              r.isPaid
                  ? 'Paid ✓'
                  : r.isOverdue
                      ? 'OVERDUE ⚠️'
                      : r.isDueSoon
                          ? 'Due Soon'
                          : 'Unpaid',
              r.isPaid
                  ? const Color(0xFF2D6A4F)
                  : r.isOverdue
                      ? const Color(0xFFE53935)
                      : r.isDueSoon
                          ? const Color(0xFFF57C00)
                          : const Color(0xFF888888),
            ),

            if (!r.isPaid) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline_rounded,
                      size: 18),
                  label: const Text('Mark as Paid',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    AppStore.instance.markReceivablePaid(r.id);
                    setState(() {});
                    Navigator.pop(ctx);
                    _showSnack('✅ Marked as paid!',
                        color: const Color(0xFF2D6A4F));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A4F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Receivable r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Receivable?',
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
            'Delete the ₱${r.amount.toStringAsFixed(2)} entry for ${r.customerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: const Text('Delete'),
            onPressed: () {
              AppStore.instance.deleteReceivable(r.id);
              setState(() {});
              Navigator.pop(ctx);
              _showSnack('🗑️ Deleted.',
                  color: const Color(0xFFE53935));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg,
      {Color color = const Color(0xFF2D6A4F)}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Widget _detailRow(String label, String value, Color valueColor,
      {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: valueColor,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal)),
        ),
      ],
    );
  }

  Widget _receivableCard(Receivable r) {
    final statusColor = r.isOverdue
        ? const Color(0xFFE53935)
        : r.isDueSoon
            ? const Color(0xFFF57C00)
            : const Color(0xFF2D6A4F);

    return GestureDetector(
      onTap: () => _showDetailDialog(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 6,
                offset: Offset(0, 2))
          ],
          border: (r.isOverdue || r.isDueSoon)
              ? Border.all(color: statusColor.withOpacity(0.4))
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  const Color(0xFFE8572A).withOpacity(0.1),
              child: Text(r.customerName[0],
                  style: const TextStyle(
                      color: Color(0xFFE8572A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.customerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  if (r.itemsSummary.isNotEmpty)
                    Text(
                      r.itemsSummary.take(2).join(', ') +
                          (r.itemsSummary.length > 2 ? '…' : ''),
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (r.dueDate != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 10, color: statusColor),
                        const SizedBox(width: 3),
                        Text(
                          r.isOverdue
                              ? 'Overdue since ${_formatDate(r.dueDate!)}'
                              : r.isDueSoon
                                  ? 'Due ${_formatDate(r.dueDate!)} — soon!'
                                  : 'Due ${_formatDate(r.dueDate!)}',
                          style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight:
                                  (r.isOverdue || r.isDueSoon)
                                      ? FontWeight.bold
                                      : FontWeight.normal),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₱${r.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFFE8572A))),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: r.isPaid
                        ? const Color(0xFF2D6A4F).withOpacity(0.1)
                        : statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    r.isPaid
                        ? 'PAID'
                        : r.isOverdue
                            ? 'OVERDUE'
                            : r.isDueSoon
                                ? 'DUE SOON'
                                : 'UNPAID',
                    style: TextStyle(
                        color: r.isPaid
                            ? const Color(0xFF2D6A4F)
                            : statusColor,
                        fontSize: 9,
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

  @override
  Widget build(BuildContext context) {
    final unpaid = _unpaid;
    final paid = _paid;
    final store = AppStore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFE8572A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Entry',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 3,
      ),
      body: Column(
        children: [
          // ── Summary banner ──────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8572A), Color(0xFFFF8C5A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Text('💳', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Receivables',
                                style: TextStyle(
                                    color: Color(0xFFFFD4C2),
                                    fontSize: 11)),
                            Text(
                              '₱${store.totalReceivables.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Overdue',
                              style: TextStyle(
                                  color: Color(0xFFFFD4C2),
                                  fontSize: 11)),
                          Text(
                            '${store.overdueReceivables}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (store.overdueReceivables > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEB),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: const Color(0xFFFFB3B3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFE53935), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${store.overdueReceivables} receivable${store.overdueReceivables > 1 ? 's are' : ' is'} overdue! Remind your customers.',
                            style: const TextStyle(
                                color: Color(0xFFE53935),
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone…',
                    prefixIcon: const Icon(Icons.search,
                        size: 20, color: Color(0xFFAAAAAA)),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),

                TabBar(
                  controller: _tabCtrl,
                  labelColor: const Color(0xFFE8572A),
                  unselectedLabelColor: const Color(0xFF888888),
                  indicatorColor: const Color(0xFFE8572A),
                  tabs: [
                    Tab(text: 'Unpaid (${unpaid.length})'),
                    Tab(text: 'Paid (${paid.length})'),
                  ],
                ),
              ],
            ),
          ),

          // ── Lists ────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                unpaid.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🎉', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 12),
                            Text('No unpaid receivables!',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(12, 12, 12, 90),
                        itemCount: unpaid.length,
                        itemBuilder: (_, i) =>
                            _receivableCard(unpaid[i]),
                      ),
                paid.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('📭', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 12),
                            Text('No paid receivables yet',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(12, 12, 12, 90),
                        itemCount: paid.length,
                        itemBuilder: (_, i) => _receivableCard(paid[i]),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── RECEIVABLE FORM SHEET ────────────────────────────────────────────────────

class _ReceivableFormSheet extends StatefulWidget {
  final void Function(Receivable) onSaved;
  const _ReceivableFormSheet({required this.onSaved});

  @override
  State<_ReceivableFormSheet> createState() => _ReceivableFormSheetState();
}

class _ReceivableFormSheetState extends State<_ReceivableFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();

  Customer? _selectedCustomer;
  DateTime? _dueDate;

  // Items loaned: product → quantity
  final Map<Product, int> _loanedItems = {};

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _computedTotal => _loanedItems.entries
      .fold(0.0, (s, e) => s + e.key.price * e.value);

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  // ── Customer picker ────────────────────────────────────────────────────────
  Future<void> _pickCustomer() async {
    final customers = AppStore.instance.customers;
    final picked = await showDialog<Customer>(
      context: context,
      builder: (ctx) => _CustomerPickerDialog(
        customers: customers,
        selected: _selectedCustomer,
      ),
    );
    if (picked != null) setState(() => _selectedCustomer = picked);
  }

  // ── Item picker ────────────────────────────────────────────────────────────
  Future<void> _showItemPicker() async {
    final products = AppStore.instance.products
        .where((p) => !p.isOutOfStock)
        .toList();

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No products available in inventory.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => _ItemPickerDialog(
        products: products,
        currentItems: Map.from(_loanedItems),
        onConfirm: (items) => setState(() {
          _loanedItems.clear();
          _loanedItems.addAll(items);
        }),
      ),
    );
  }

  void _save() {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a customer.'),
        backgroundColor: Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_loanedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please add at least one item.'),
        backgroundColor: Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final itemsSummary = _loanedItems.entries
        .map((e) => '${e.value}× ${e.key.name}')
        .toList();

    final r = Receivable(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: _selectedCustomer!.name,
      customerPhone: _selectedCustomer!.phone,
      amount: _computedTotal,
      dateCreated: DateTime.now(),
      dueDate: _dueDate,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      itemsSummary: itemsSummary,
    );

    Navigator.pop(context);
    widget.onSaved(r);
  }

  InputDecoration _inputDeco(String label, [IconData? icon]) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: const Color(0xFFAAAAAA))
            : null,
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFFE8572A), width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Text('💳 New Utang / Receivable',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // ── Customer selector ─────────────────────────────
              const Text('Customer *',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444))),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickCustomer,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(10),
                    border: _selectedCustomer != null
                        ? Border.all(
                            color: const Color(0xFFE8572A).withOpacity(0.5),
                            width: 1.5)
                        : null,
                  ),
                  child: Row(
                    children: [
                      if (_selectedCustomer != null) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: _selectedCustomer!.tierColor
                              .withOpacity(0.15),
                          child: Text(
                            _selectedCustomer!.name[0],
                            style: TextStyle(
                                color: _selectedCustomer!.tierColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedCustomer!.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              Text(_selectedCustomer!.phone,
                                  style: const TextStyle(
                                      color: Color(0xFF888888),
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.person_search_outlined,
                            color: Color(0xFFAAAAAA), size: 20),
                        const SizedBox(width: 10),
                        const Text('Select a customer from your list',
                            style: TextStyle(
                                color: Color(0xFFAAAAAA), fontSize: 13)),
                        const Spacer(),
                      ],
                      const Icon(Icons.arrow_drop_down_rounded,
                          color: Color(0xFFAAAAAA)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Items loaned ──────────────────────────────────
              Row(
                children: [
                  const Text('Items Loaned',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF444444))),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showItemPicker,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Items'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE8572A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (_loanedItems.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.shopping_basket_outlined,
                          color: Color(0xFFCCCCCC), size: 28),
                      SizedBox(height: 6),
                      Text('No items added yet',
                          style: TextStyle(
                              color: Color(0xFFAAAAAA), fontSize: 12)),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      ..._loanedItems.entries.map((e) => ListTile(
                            dense: true,
                            leading: Text(e.key.emoji,
                                style: const TextStyle(fontSize: 20)),
                            title: Text(e.key.name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${e.value} ${e.key.unit} × ₱${e.key.price.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11)),
                            trailing: Text(
                                '₱${(e.key.price * e.value).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE8572A))),
                          )),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const Spacer(),
                            Text(
                              '₱${_computedTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFFE8572A)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // ── Notes ─────────────────────────────────────────
              TextFormField(
                controller: _notesCtrl,
                decoration: _inputDeco(
                    'Notes (optional)', Icons.sticky_note_2_outlined),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // ── Due date picker ────────────────────────────────
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                    builder: (c, child) => Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: const ColorScheme.light(
                            primary: Color(0xFFE8572A)),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(10),
                    border: _dueDate != null
                        ? Border.all(
                            color: const Color(0xFFE8572A), width: 1.5)
                        : null,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: Color(0xFFAAAAAA)),
                      const SizedBox(width: 10),
                      Text(
                        _dueDate != null
                            ? 'Due: ${_formatDate(_dueDate!)}'
                            : 'Set due date (optional)',
                        style: TextStyle(
                            fontSize: 13,
                            color: _dueDate != null
                                ? const Color(0xFF1A1A2E)
                                : const Color(0xFFAAAAAA)),
                      ),
                      const Spacer(),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: Color(0xFFAAAAAA)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save Receivable',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8572A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CUSTOMER PICKER DIALOG ───────────────────────────────────────────────────

class _CustomerPickerDialog extends StatefulWidget {
  final List<Customer> customers;
  final Customer? selected;
  const _CustomerPickerDialog(
      {required this.customers, this.selected});

  @override
  State<_CustomerPickerDialog> createState() =>
      _CustomerPickerDialogState();
}

class _CustomerPickerDialogState extends State<_CustomerPickerDialog> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.customers
        .where((c) =>
            c.name.toLowerCase().contains(_search.toLowerCase()) ||
            c.phone.contains(_search))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Select Customer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search customers…',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: Color(0xFFAAAAAA)),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No customers found',
                          style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final isSel = c.id == widget.selected?.id;
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                c.tierColor.withOpacity(0.15),
                            child: Text(c.name[0],
                                style: TextStyle(
                                    color: c.tierColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ),
                          title: Text(c.name,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSel
                                      ? const Color(0xFFE8572A)
                                      : const Color(0xFF1A1A2E))),
                          subtitle: Text(c.phone,
                              style: const TextStyle(fontSize: 11)),
                          trailing: isSel
                              ? const Icon(Icons.check_rounded,
                                  color: Color(0xFFE8572A), size: 18)
                              : null,
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}

// ─── ITEM PICKER DIALOG ───────────────────────────────────────────────────────

class _ItemPickerDialog extends StatefulWidget {
  final List<Product> products;
  final Map<Product, int> currentItems;
  final void Function(Map<Product, int>) onConfirm;

  const _ItemPickerDialog({
    required this.products,
    required this.currentItems,
    required this.onConfirm,
  });

  @override
  State<_ItemPickerDialog> createState() => _ItemPickerDialogState();
}

class _ItemPickerDialogState extends State<_ItemPickerDialog> {
  late Map<Product, int> _items;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _items = Map.from(widget.currentItems);
  }

  List<Product> get _filtered => widget.products
      .where((p) =>
          p.name.toLowerCase().contains(_search.toLowerCase()) ||
          p.category.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalSelected =
        _items.values.fold(0, (s, q) => s + q);

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Text('Add Items',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          if (totalSelected > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8572A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$totalSelected selected',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search products…',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: Color(0xFFAAAAAA)),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  final qty = _items[p] ?? 0;
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                          child: Text(p.emoji,
                              style: const TextStyle(fontSize: 18))),
                    ),
                    title: Text(p.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '₱${p.price.toStringAsFixed(2)} / ${p.unit}  ·  ${p.stock} in stock',
                        style: const TextStyle(fontSize: 10)),
                    trailing: qty == 0
                        ? GestureDetector(
                            onTap: () =>
                                setState(() => _items[p] = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8572A),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Text('Add',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() {
                                  if (qty <= 1)
                                    _items.remove(p);
                                  else
                                    _items[p] = qty - 1;
                                }),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F0F0),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.remove,
                                      size: 14),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                child: Text('$qty',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ),
                              GestureDetector(
                                onTap: () => setState(() {
                                  if (qty < p.stock)
                                    _items[p] = qty + 1;
                                }),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8572A),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.add,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_items);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8572A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}