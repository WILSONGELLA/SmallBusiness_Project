import 'package:flutter/material.dart';
import '../models/app_state.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            labelColor: const Color(0xFFE8572A),
            unselectedLabelColor: const Color(0xFF888888),
            indicatorColor: const Color(0xFFE8572A),
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.point_of_sale_rounded, size: 18), text: 'New Sale'),
              Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'History'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              NewSaleTab(onSaleComplete: () => setState(() {})),
              const HistoryTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── NEW SALE TAB ─────────────────────────────────────────────────────────────

class NewSaleTab extends StatefulWidget {
  final VoidCallback onSaleComplete;
  const NewSaleTab({super.key, required this.onSaleComplete});

  @override
  State<NewSaleTab> createState() => _NewSaleTabState();
}

class _NewSaleTabState extends State<NewSaleTab> {
  final store = AppStore.instance;
  final List<ReceiptItem> _cart = [];
  Customer? _selectedCustomer;
  String _search = '';
  String _paymentMethod = 'Cash';
  final _amountPaidCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to store changes and rebuild when products/inventory updates
    store.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountPaidCtrl.dispose();
    super.dispose();
  }

  double get _cartSubtotal => _cart.fold(0, (s, i) => s + i.subtotal);
  double get _customerDiscount => _selectedCustomer?.discountRate ?? 0;
  double get _discountAmount => _cartSubtotal * (_customerDiscount / 100);
  double get _grandTotal => _cartSubtotal - _discountAmount;
  double get _amountPaid =>
      double.tryParse(_amountPaidCtrl.text) ?? 0;
  double get _change => _amountPaid - _grandTotal;

  List<Product> get _availableProducts {
    final q = _search.toLowerCase();
    return store.products
        .where((p) =>
            !p.isOutOfStock &&
            (q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q)))
        .toList();
  }

  void _addToCart(Product p) {
    setState(() {
      final idx = _cart.indexWhere((i) => i.product.id == p.id);
      if (idx >= 0) {
        final existing = _cart[idx];
        if (existing.quantity < p.stock) {
          _cart[idx] = ReceiptItem(
            product: existing.product,
            quantity: existing.quantity + 1,
            unitPrice: existing.unitPrice,
          );
        }
      } else {
        _cart.add(ReceiptItem(product: p, quantity: 1, unitPrice: p.price));
      }
    });
  }

  void _removeFromCart(ReceiptItem item) {
    setState(() {
      final idx = _cart.indexOf(item);
      if (item.quantity > 1) {
        _cart[idx] = ReceiptItem(
            product: item.product,
            quantity: item.quantity - 1,
            unitPrice: item.unitPrice);
      } else {
        _cart.remove(item);
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _selectedCustomer = null;
      _amountPaidCtrl.clear();
    });
  }

  void _checkout() {
    if (_cart.isEmpty) {
      _snack('Add items to the cart first.', isError: true);
      return;
    }
    if (_paymentMethod == 'Cash' &&
        (_amountPaidCtrl.text.isEmpty ||
            _amountPaid < _grandTotal)) {
      _snack('Amount paid must be ≥ ₱${_grandTotal.toStringAsFixed(2)}',
          isError: true);
      return;
    }

    final txn = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      items: List.from(_cart),
      customer: _selectedCustomer,
      discountRate: _customerDiscount,
      paymentMethod: _paymentMethod,
      amountPaid: _paymentMethod == 'Cash' ? _amountPaid : _grandTotal,
    );

    store.addTransaction(txn);
    _clearCart();
    widget.onSaleComplete();

    _showReceipt(txn);
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor:
          isError ? const Color(0xFFE53935) : const Color(0xFF2D6A4F),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showReceipt(Transaction txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ReceiptSheet(txn: txn),
    );
  }

  void _pickCustomer() async {
    final result = await showModalBottomSheet<Customer?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CustomerPickerSheet(selected: _selectedCustomer),
    );
    setState(() => _selectedCustomer = result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Product search ──────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search products to add…',
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFFAAAAAA)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Product grid ─────────────────────────────────────────────
              Expanded(
                flex: 3,
                child: _availableProducts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('📭', style: TextStyle(fontSize: 40)),
                            SizedBox(height: 8),
                            Text('No products found',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _availableProducts.length,
                        itemBuilder: (_, i) {
                          final p = _availableProducts[i];
                          final inCart = _cart
                              .where((c) => c.product.id == p.id)
                              .fold(0, (s, c) => s + c.quantity);
                          return GestureDetector(
                            onTap: () => _addToCart(p),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: inCart > 0
                                    ? Border.all(
                                        color: const Color(0xFFE8572A),
                                        width: 2,
                                      )
                                    : null,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0D000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          p.emoji,
                                          style: const TextStyle(fontSize: 28),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p.name,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '₱${p.price.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: Color(0xFFE8572A),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (inCart > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8572A),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('$inCart',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  },
),
                    // : GridView.builder(
                    //     padding: const EdgeInsets.all(10),
                    //     gridDelegate:
                    //         const SliverGridDelegateWithFixedCrossAxisCount(
                    //       crossAxisCount: 2,
                    //       childAspectRatio: 1.4,
                    //       crossAxisSpacing: 8,
                    //       mainAxisSpacing: 8,
                    //     ),
                    //     itemCount: _availableProducts.length,
                    //     itemBuilder: (_, i) {
                    //       final p = _availableProducts[i];
                    //       final inCart = _cart
                    //           .where((c) => c.product.id == p.id)
                    //           .fold(0, (s, c) => s + c.quantity);
                    //       return GestureDetector(
                    //         onTap: () => _addToCart(p),
                    //         child: Container(
                    //           decoration: BoxDecoration(
                    //             color: Colors.white,
                    //             borderRadius: BorderRadius.circular(12),
                    //             border: inCart > 0
                    //                 ? Border.all(
                    //                     color: const Color(0xFFE8572A),
                    //                     width: 2)
                    //                 : null,
                    //             boxShadow: const [
                    //               BoxShadow(
                    //                   color: Color(0x0D000000),
                    //                   blurRadius: 6,
                    //                   offset: Offset(0, 2))
                    //             ],
                    //           ),
                    //           child: Stack(
                    //             children: [
                    //               Padding(
                    //                 padding: const EdgeInsets.all(10),
                    //                 child: Column(
                    //                   crossAxisAlignment:
                    //                       CrossAxisAlignment.start,
                    //                   mainAxisAlignment:
                    //                       MainAxisAlignment.center,
                    //                   children: [
                    //                     Text(p.emoji,
                    //                         style:
                    //                             const TextStyle(fontSize: 24)),
                    //                     const SizedBox(height: 4),
                    //                     Text(p.name,
                    //                         style: const TextStyle(
                    //                             fontSize: 11,
                    //                             fontWeight: FontWeight.bold),
                    //                         maxLines: 2,
                    //                         overflow: TextOverflow.ellipsis),
                    //                     Text('₱${p.price.toStringAsFixed(2)}',
                    //                         style: const TextStyle(
                    //                             color: Color(0xFFE8572A),
                    //                             fontWeight: FontWeight.bold,
                    //                             fontSize: 13)),
                    //                   ],
                    //                 ),
                    //               ),
                    //               if (inCart > 0)
                    //                 Positioned(
                    //                   top: 6,
                    //                   right: 6,
                    //                   child: Container(
                    //                     width: 22,
                    //                     height: 22,
                    //                     decoration: const BoxDecoration(
                    //                       color: Color(0xFFE8572A),
                    //                       shape: BoxShape.circle,
                    //                     ),
                    //                     child: Center(
                    //                       child: Text('$inCart',
                    //                           style: const TextStyle(
                    //                               color: Colors.white,
                    //                               fontSize: 11,
                    //                               fontWeight: FontWeight.bold)),
                    //                     ),
                    //                   ),
                    //                 ),
                    //             ],
                    //           ),
                    //         ),
                    //       );
                    //     },
                    //   ),
              ),

              // ── Cart / order summary ──────────────────────────────────────
              Container(
                width: 180,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Color(0x15000000),
                        blurRadius: 12,
                        offset: Offset(-3, 0))
                  ],
                ),
                child: Column(
                  children: [
                    // Cart header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Color(0xFFF0F0F0))),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_cart_outlined,
                              size: 16, color: Color(0xFFE8572A)),
                          const SizedBox(width: 6),
                          const Text('Cart',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          const Spacer(),
                          if (_cart.isNotEmpty)
                            GestureDetector(
                              onTap: _clearCart,
                              child: const Icon(Icons.delete_sweep_rounded,
                                  size: 18, color: Color(0xFFE53935)),
                            ),
                        ],
                      ),
                    ),

                    // Cart items
                    Expanded(
                      child: _cart.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🛒',
                                      style: TextStyle(fontSize: 28)),
                                  SizedBox(height: 6),
                                  Text('Cart is empty',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              children: _cart.map((item) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  child: Row(
                                    children: [
                                      Text(item.product.emoji,
                                          style:
                                              const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(item.product.name,
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis),
                                            Text(
                                                '₱${item.unitPrice.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF888888))),
                                          ],
                                        ),
                                      ),
                                      // Quantity controls
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () =>
                                                _removeFromCart(item),
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF0F0F0),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                  Icons.remove_rounded,
                                                  size: 12),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            child: Text('${item.quantity}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                          GestureDetector(
                                            onTap: () => _addToCart(item.product),
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8572A),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                  Icons.add_rounded,
                                                  size: 12,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),

                    // Order summary
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Customer picker
                          GestureDetector(
                            onTap: _pickCustomer,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline,
                                      size: 14, color: Color(0xFF888888)),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      _selectedCustomer?.name ?? 'Select customer',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: _selectedCustomer != null
                                              ? const Color(0xFF1A1A2E)
                                              : const Color(0xFF888888)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      size: 14, color: Color(0xFFAAAAAA)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Totals
                          _summaryRow('Subtotal', '₱${_cartSubtotal.toStringAsFixed(2)}'),
                          if (_customerDiscount > 0) ...[
                            _summaryRow(
                                'Discount (${_customerDiscount.toInt()}%)',
                                '-₱${_discountAmount.toStringAsFixed(2)}',
                                color: const Color(0xFF2D6A4F)),
                          ],
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Divider(height: 1, color: Color(0xFFF0F0F0))),
                          _summaryRow('Total', '₱${_grandTotal.toStringAsFixed(2)}',
                              bold: true, color: const Color(0xFFE8572A)),
                          const SizedBox(height: 8),

                          // Payment method
                          Row(
                            children: ['Cash', 'GCash', 'Maya'].map((m) {
                              final sel = m == _paymentMethod;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _paymentMethod = m),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? const Color(0xFFE8572A)
                                          : const Color(0xFFF0F0F0),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(m,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: sel
                                                ? Colors.white
                                                : const Color(0xFF666666))),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (_paymentMethod == 'Cash') ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: _amountPaidCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Amount paid',
                                hintStyle: const TextStyle(
                                    fontSize: 11, color: Color(0xFFCCCCCC)),
                                prefixText: '₱ ',
                                prefixStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE8572A), width: 1.5)),
                              ),
                            ),
                            if (_amountPaid >= _grandTotal &&
                                _grandTotal > 0) ...[
                              const SizedBox(height: 4),
                              _summaryRow(
                                  'Change',
                                  '₱${_change.toStringAsFixed(2)}',
                                  color: const Color(0xFF2D6A4F)),
                            ],
                          ],
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _cart.isEmpty ? null : _checkout,
                            icon: const Icon(Icons.receipt_long_rounded,
                                size: 16),
                            label: const Text('Checkout',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8572A),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFFEEECE8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? const Color(0xFF555555))),
          Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  color: color ?? const Color(0xFF1A1A2E))),
        ],
      ),
    );
  }
}

// ─── HISTORY TAB ──────────────────────────────────────────────────────────────

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final store = AppStore.instance;

  @override
  Widget build(BuildContext context) {
    final txns = store.transactions;

    if (txns.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🧾', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No transactions yet',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            SizedBox(height: 4),
            Text('Complete a sale to see it here',
                style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
          ],
        ),
      );
    }

    // Daily totals header
    final todayTotal = store.totalSalesToday;
    final todayCount = store.transactionsToday;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(12),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's Sales",
                        style: TextStyle(
                            color: Color(0xFFFFD4C2), fontSize: 11)),
                    Text('₱${todayTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Transactions',
                      style:
                          TextStyle(color: Color(0xFFFFD4C2), fontSize: 11)),
                  Text('$todayCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            itemCount: txns.length,
            itemBuilder: (_, i) {
              final t = txns[i];
              return GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (_) => ReceiptSheet(txn: t),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 6,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                            child: Text('🧾',
                                style: TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.receiptNumber,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                                '${t.items.length} item(s) · ${t.paymentMethod}'
                                '${t.customer != null ? ' · ${t.customer!.name.split(' ').first}' : ''}',
                                style: const TextStyle(
                                    color: Color(0xFF888888), fontSize: 11)),
                            Text(
                                _formatDate(t.date),
                                style: const TextStyle(
                                    color: Color(0xFFAAAAAA), fontSize: 10)),
                          ],
                        ),
                      ),
                      Text('₱${t.grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFFE8572A))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${d.month}/${d.day}/${d.year} ${_h(d.hour)}:${_m(d.minute)} ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _h(int h) => (h > 12 ? h - 12 : (h == 0 ? 12 : h)).toString();
  String _m(int m) => m.toString().padLeft(2, '0');
}

// ─── RECEIPT SHEET ────────────────────────────────────────────────────────────

class ReceiptSheet extends StatelessWidget {
  final Transaction txn;
  const ReceiptSheet({super.key, required this.txn});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final business = store.currentUser?.businessName ?? 'TindaHan Store';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    // Header
                    const Text('🏪', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 6),
                    Text(business,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Georgia')),
                    Text(txn.receiptNumber,
                        style: const TextStyle(
                            color: Color(0xFF888888), fontSize: 12)),
                    Text(_fullDate(txn.date),
                        style: const TextStyle(
                            color: Color(0xFFAAAAAA), fontSize: 11)),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 8),

                    // Items
                    ...txn.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Text('${item.product.emoji} ',
                                  style: const TextStyle(fontSize: 16)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                        '${item.quantity} × ₱${item.unitPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF888888))),
                                  ],
                                ),
                              ),
                              Text('₱${item.subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ],
                          ),
                        )),

                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 8),

                    // Totals
                    _row('Subtotal', '₱${txn.subtotal.toStringAsFixed(2)}'),
                    if (txn.discountRate > 0) ...[
                      _row(
                          'Discount (${txn.discountRate.toInt()}%)',
                          '-₱${txn.discountAmount.toStringAsFixed(2)}',
                          color: const Color(0xFF2D6A4F)),
                      if (txn.customer != null)
                        Text('Applied for ${txn.customer!.name.split(' ').first}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF2D6A4F),
                                fontStyle: FontStyle.italic)),
                    ],
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Divider(
                            color: Color(0xFFEEEEEE), thickness: 1.5)),
                    _row('TOTAL', '₱${txn.grandTotal.toStringAsFixed(2)}',
                        bold: true, large: true, color: const Color(0xFFE8572A)),
                    const SizedBox(height: 10),
                    _row('Payment', txn.paymentMethod),
                    _row('Amount Paid', '₱${txn.amountPaid.toStringAsFixed(2)}'),
                    if (txn.paymentMethod == 'Cash')
                      _row('Change', '₱${txn.change.toStringAsFixed(2)}',
                          color: const Color(0xFF2D6A4F)),

                    if (txn.customer != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Text('👤 ', style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(txn.customer!.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  Text(txn.customer!.tier,
                                      style: TextStyle(
                                          color: txn.customer!.tierColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Text('— Thank you for shopping! —',
                        style: TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 12,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 8),
                    const Text('Powered by TindaHan 🏪',
                        style: TextStyle(
                            color: Color(0xFFCCCCCC), fontSize: 10)),
                  ],
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Done',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8572A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, bool large = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: large ? 14 : 12,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? const Color(0xFF555555))),
          Text(value,
              style: TextStyle(
                  fontSize: large ? 16 : 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  color: color ?? const Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  String _fullDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month - 1]} ${d.day}, ${d.year}  $h:$m $ampm';
  }
}

// ─── CUSTOMER PICKER SHEET ────────────────────────────────────────────────────

class _CustomerPickerSheet extends StatefulWidget {
  final Customer? selected;
  const _CustomerPickerSheet({required this.selected});

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = AppStore.instance.customers
        .where((c) =>
            _q.isEmpty ||
            c.name.toLowerCase().contains(_q.toLowerCase()) ||
            c.phone.contains(_q))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          const Text('Select Customer',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'Search customers…',
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          // Walk-in option
          ListTile(
            leading: const CircleAvatar(
                backgroundColor: Color(0xFFF0F0F0),
                child: Text('👣', style: TextStyle(fontSize: 16))),
            title: const Text('Walk-in customer',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('No discount applied',
                style: TextStyle(fontSize: 11)),
            selected: widget.selected == null,
            selectedTileColor: const Color(0xFFFFF0EB),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () => Navigator.pop(context, null),
          ),
          const Divider(height: 8),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final c = filtered[i];
                final sel = widget.selected?.id == c.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: c.tierColor.withOpacity(0.15),
                    child: Text(c.name[0],
                        style: TextStyle(
                            color: c.tierColor,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(c.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                      '${c.tier} · ${c.discountRate.toInt()}% off',
                      style: const TextStyle(fontSize: 11)),
                  selected: sel,
                  selectedTileColor: const Color(0xFFFFF0EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () => Navigator.pop(context, c),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}