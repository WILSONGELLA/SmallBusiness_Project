import 'package:flutter/material.dart';
import '../models/app_state.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final List<Customer> _customers = List.from(AppData.sampleCustomers);
  String _search = '';
  String _filter = 'All';

  List<Customer> get filtered {
    return _customers.where((c) {
      final matchSearch =
          c.name.toLowerCase().contains(_search.toLowerCase()) ||
              c.phone.contains(_search);
      final matchFilter = _filter == 'All' ||
          (_filter == 'Loyal' && c.isAvid) ||
          (_filter == 'New' && !c.isAvid);
      return matchSearch && matchFilter;
    }).toList()
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
  }

  void _showCustomerDialog({Customer? customer}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final notesCtrl = TextEditingController(text: customer?.notes ?? '');
    final purchasesCtrl = TextEditingController(
        text: customer != null ? customer.purchaseCount.toString() : '');
    final spentCtrl = TextEditingController(
        text: customer != null ? customer.totalSpent.toStringAsFixed(0) : '');
    bool isAvid = customer?.isAvid ?? false;
    double discount = customer?.discountRate ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: Form(
            key: formKey,
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

                  // Title + delete button
                  Row(
                    children: [
                      Text(
                        customer == null
                            ? '👤 New Customer'
                            : '✏️ Edit Customer',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (customer != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Color(0xFFE53935)),
                          tooltip: 'Delete customer',
                          onPressed: () => _confirmDelete(ctx, customer),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name
                  TextFormField(
                    controller: nameCtrl,
                    decoration: _inputDeco('Full name *', Icons.person_outline),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: _inputDeco('Phone number *', Icons.phone_outlined),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      if (v.trim().length < 7) {
                        return 'Number seems too short';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Purchase history (for editing)
                  if (customer != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: purchasesCtrl,
                            decoration:
                                _inputDeco('No. of Purchases', Icons.shopping_bag_outlined),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: spentCtrl,
                            decoration:
                                _inputDeco('Total Spent (₱)', Icons.payments_outlined),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Notes
                  TextFormField(
                    controller: notesCtrl,
                    decoration: _inputDeco(
                        'Notes (optional)', Icons.sticky_note_2_outlined),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // ── Suki / Avid toggle ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isAvid
                          ? const Color(0xFFFFF0EB)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(14),
                      border: isAvid
                          ? Border.all(color: const Color(0xFFE8572A).withOpacity(0.3))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Loyal Customer',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(
                                isAvid
                                    ? 'This customer will receive a special discount'
                                    : 'Enable to grant a discount',
                                style: const TextStyle(
                                    color: Color(0xFF888888), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isAvid,
                          activeColor: const Color(0xFFE8572A),
                          onChanged: (v) => setModal(() {
                            isAvid = v;
                            if (!v) discount = 0;
                          }),
                        ),
                      ],
                    ),
                  ),

                  // ── Discount slider (shown only when avid) ─────────
                  if (isAvid) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8572A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${discount.toInt()}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: discount,
                      min: 0,
                      max: 25,
                      divisions: 5,
                      activeColor: const Color(0xFFE8572A),
                      inactiveColor: const Color(0xFFEEECE8),
                      label: '${discount.toInt()}%',
                      onChanged: (v) => setModal(() => discount = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['0%', '5%', '10%', '15%', '20%', '25%']
                          .map((t) => Text(t,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: Icon(
                          customer == null
                              ? Icons.person_add_rounded
                              : Icons.save_rounded,
                          size: 18),
                      label: Text(
                        customer == null ? 'Save Customer' : 'Update',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        setState(() {
                          if (customer == null) {
                            _customers.add(Customer(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              isAvid: isAvid,
                              discountRate: isAvid ? discount : 0,
                              notes: notesCtrl.text.trim().isEmpty
                                  ? null
                                  : notesCtrl.text.trim(),
                            ));
                          } else {
                            customer.name = nameCtrl.text.trim();
                            customer.phone = phoneCtrl.text.trim();
                            customer.isAvid = isAvid;
                            customer.discountRate = isAvid ? discount : 0;
                            customer.notes = notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim();
                            if (purchasesCtrl.text.trim().isNotEmpty) {
                              customer.purchaseCount =
                                  int.tryParse(purchasesCtrl.text.trim()) ??
                                      customer.purchaseCount;
                            }
                            if (spentCtrl.text.trim().isNotEmpty) {
                              customer.totalSpent =
                                  double.tryParse(spentCtrl.text.trim()) ??
                                      customer.totalSpent;
                            }
                          }
                        });
                        Navigator.pop(ctx);
                        _showSuccessSnack(
                          customer == null
                              ? '✅ "${nameCtrl.text.trim()}" has been added as a customer!'
                              : '✅ Information updated for ${nameCtrl.text.trim()}!',
                        );
                      },
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
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext sheetCtx, Customer customer) {
    Navigator.pop(sheetCtx);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete ${customer.name}?',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content:
            const Text('All of their information will be lost. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: const Text('Delete'),
            onPressed: () {
              setState(() =>
                  _customers.removeWhere((c) => c.id == customer.id));
              Navigator.pop(ctx);
              _showSuccessSnack('🗑️ "${customer.name}" has been deleted.',
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

  void _showSuccessSnack(String msg, {Color color = const Color(0xFF2D6A4F)}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  InputDecoration _inputDeco(String label, [IconData? icon]) => InputDecoration(
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
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFFE53935), width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFFE53935), width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    final items = filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
 
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerDialog(),
        backgroundColor: const Color(0xFFE8572A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('New Customer',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 3,
      ),
      body: Column(
        children: [
          // ── Search + filter chips ──────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search customers...',
                    prefixIcon: const Icon(Icons.search,
                        size: 20, color: Color(0xFFAAAAAA)),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: ['All', 'Loyal', 'New'].map((f) {
                    final sel = f == _filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFE8572A)
                                : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(f,
                              style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : const Color(0xFF666666),
                                  fontSize: 12,
                                  fontWeight: sel
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── Summary bar ────────────────────────────────────
          Container(
            color: const Color(0xFFF7F5F2),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _summaryChip(
                    '${_customers.length}', 'Total', const Color(0xFF1A1A2E)),
                const SizedBox(width: 10),
                _summaryChip(
                    '${_customers.where((c) => c.isAvid).length}',
                    'Loyal',
                    const Color(0xFFE8572A)),
                const SizedBox(width: 10),
                _summaryChip(
                    '${_customers.where((c) => !c.isAvid).length}',
                    'New',
                    const Color(0xFF78909C)),
              ],
            ),
          ),

          // ── Customer list ──────────────────────────────────
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('👥',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        const Text('No customers found',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showCustomerDialog(),
                          icon: const Icon(Icons.person_add_rounded,
                              size: 16),
                          label: const Text('Add a customer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8572A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final c = items[i];
                      return GestureDetector(
                        onTap: () => _showCustomerDialog(customer: c),
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
                            border: c.isAvid
                                ? Border.all(
                                    color: const Color(0xFFE8572A)
                                        .withOpacity(0.3))
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Avatar with star badge
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        c.tierColor.withOpacity(0.15),
                                    child: Text(c.name[0],
                                        style: TextStyle(
                                            color: c.tierColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18)),
                                  ),
                                  if (c.isAvid)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE8572A),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Text('⭐',
                                              style: TextStyle(fontSize: 9)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(c.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                c.tierColor.withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(c.tier,
                                              style: TextStyle(
                                                  color: c.tierColor,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(c.phone,
                                        style: const TextStyle(
                                            color: Color(0xFF888888),
                                            fontSize: 12)),
                                    if (c.notes != null)
                                      Text('📝 ${c.notes}',
                                          style: const TextStyle(
                                              color: Color(0xFF888888),
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      '₱${c.totalSpent.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF1A1A2E))),
                                  Text('${c.purchaseCount} purchases',
                                      style: const TextStyle(
                                          color: Color(0xFF888888),
                                          fontSize: 11)),
                                  if (c.isAvid) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8572A),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${c.discountRate.toInt()}% OFF',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String value, String label, Color color) {
    return Row(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
      ],
    );
  }
}
