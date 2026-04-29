import 'package:flutter/material.dart';
import '../models/app_state.dart';

class InventoryScreen extends StatefulWidget {
  final String initialCategory;
  const InventoryScreen({super.key, this.initialCategory = 'All'});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<Product> _products = List.from(AppData.sampleProducts);
  String _search = '';
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void didUpdateWidget(InventoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      setState(() => _selectedCategory = widget.initialCategory);
    }
  }

  List<String> get categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<Product> get filtered {
    return _products.where((p) {
      final matchSearch =
          p.name.toLowerCase().contains(_search.toLowerCase()) ||
              p.category.toLowerCase().contains(_search.toLowerCase());
      final matchCat =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();
  }

  // ── Add / Edit bottom sheet ──────────────────────────────────────────────
  void _showAddEditDialog({Product? product}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl =
        TextEditingController(text: product != null ? product.price.toString() : '');
    final stockCtrl =
        TextEditingController(text: product != null ? product.stock.toString() : '');
    final unitCtrl = TextEditingController(text: product?.unit ?? 'pack');
    final catCtrl = TextEditingController(
        text: product?.category ??
            (_selectedCategory == 'All' ? '' : _selectedCategory));
    final emojiCtrl = TextEditingController(text: product?.emoji ?? '📦');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
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

                // Title row
                Row(
                  children: [
                    Text(
                      product == null
                          ? '➕ New Product'
                          : '✏️ Edit Product',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (product != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFE53935)),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(ctx, product),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Emoji + Name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: TextFormField(
                        controller: emojiCtrl,
                        decoration: _inputDeco('Emoji'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: nameCtrl,
                        decoration: _inputDeco('Product name *'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price + Stock
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceCtrl,
                        decoration: _inputDeco('Price (₱) *'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter a price';
                          }
                          if (double.tryParse(v) == null) {
                            return 'Not a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: stockCtrl,
                        decoration: _inputDeco('Stock Qty *').copyWith(
                            prefix: IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () {
                                stockCtrl.text = ((int.tryParse(stockCtrl.text) ?? 0) - 1).toString();
                              },
                            ),suffix: IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                stockCtrl.text = ((int.tryParse(stockCtrl.text) ?? 0) + 1).toString();
                              },
                            )
                          ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter stock quantity';
                          }
                          if (int.tryParse(v) == null) {
                            return 'Must be a whole number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category + Unit
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownMenu<String>(
                        dropdownMenuEntries: categories
                            .map((cat) => DropdownMenuEntry<String>(
                                  value: cat,
                                  label: cat,
                                ))
                            .toList(),
                        initialSelection:
                            catCtrl.text.isEmpty ? null : catCtrl.text,
                        onSelected: (String? value) {
                          if (value != null) {
                            catCtrl.text = value;
                          }
                        },
                        inputDecorationTheme: InputDecorationTheme(
                          constraints:
                              const BoxConstraints(minHeight: 48),
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF7F7F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xFFE8572A), width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          labelStyle:
                              const TextStyle(fontSize: 12),
                        ),
                        label: const Text('Category *'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownMenu<String>(
                        dropdownMenuEntries: ['Pack', 'Sachet', 'Bottle', 'Can', 'Piece']
                            .map((unit) => DropdownMenuEntry<String>(
                                  value: unit,
                                  label: unit,
                                ))
                            .toList(),
                        initialSelection:
                            unitCtrl.text.isEmpty ? null : unitCtrl.text,
                        onSelected: (String? value) {
                          if (value != null) {
                            unitCtrl.text = value;
                          }
                        },
                        inputDecorationTheme: InputDecorationTheme(
                          constraints:
                              const BoxConstraints(minHeight: 48),
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF7F7F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xFFE8572A), width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          labelStyle:
                              const TextStyle(fontSize: 12),
                        ),
                        label: const Text('Unit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: Icon(
                        product == null ? Icons.add_rounded : Icons.save_rounded,
                        size: 18),
                    label: Text(
                      product == null ? 'Save Product' : 'Update',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      setState(() {
                        if (product == null) {
                          _products.add(Product(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: nameCtrl.text.trim(),
                            category: catCtrl.text.trim(),
                            price: double.parse(priceCtrl.text.trim()),
                            stock: int.parse(stockCtrl.text.trim()),
                            unit: unitCtrl.text.trim().isEmpty
                                ? 'piece'
                                : unitCtrl.text.trim(),
                            emoji: emojiCtrl.text.trim().isEmpty
                                ? '📦'
                                : emojiCtrl.text.trim(),
                          ));
                        } else {
                          product.name = nameCtrl.text.trim();
                          product.category = catCtrl.text.trim();
                          product.price = double.parse(priceCtrl.text.trim());
                          product.stock = int.parse(stockCtrl.text.trim());
                          product.unit = unitCtrl.text.trim().isEmpty
                              ? 'piece'
                              : unitCtrl.text.trim();
                          product.emoji = emojiCtrl.text.trim().isEmpty
                              ? '📦'
                              : emojiCtrl.text.trim();
                        }
                      });
                      Navigator.pop(ctx);
                      _showSuccessSnack(
                        product == null
                            ? '✅ "${nameCtrl.text.trim()}" has been added!'
                            : '✅ Product updated successfully!',
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
    );
  }

  // ── Delete confirmation ──────────────────────────────────────────────────
  void _confirmDelete(BuildContext sheetCtx, Product product) {
    Navigator.pop(sheetCtx); // close sheet first
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete ang ${product.emoji} ${product.name}?',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('This cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: const Text('Delete'),
            onPressed: () {
              setState(() => _products.removeWhere((p) => p.id == product.id));
              Navigator.pop(ctx);
              _showSuccessSnack('🗑️ "${product.name}" has been deleted.',
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
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
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

  Color _stockColor(Product p) {
    if (p.isOutOfStock) return const Color(0xFFE53935);
    if (p.isLowStock) return const Color(0xFFF57C00);
    return const Color(0xFF2D6A4F);
  }

  @override
  Widget build(BuildContext context) {
    final items = filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      // ── FAB ─────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFFE8572A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Product',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 3,
      ),
      body: Column(
        children: [
          // ── Search + category chips ────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
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
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final sel = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFE8572A)
                                : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF666666),
                              fontSize: 12,
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Active filter banner ───────────────────────────
          if (_selectedCategory != 'All')
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF0EB),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_rounded,
                      size: 14, color: Color(0xFFE8572A)),
                  const SizedBox(width: 6),
                  Text(
                    '$_selectedCategory · ${items.length} item${items.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE8572A),
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = 'All'),
                    child: const Text('Clear',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE8572A),
                            decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),

          // ── Product list ───────────────────────────────────
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📭',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        const Text('No products found',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 14)),
                        if (_selectedCategory != 'All') ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(
                                () => _selectedCategory = 'All'),
                            child: const Text('View all',
                                style: TextStyle(
                                    color: Color(0xFFE8572A))),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showAddEditDialog(),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add a product'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8572A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final p = items[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
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
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0EB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                                child: Text(p.emoji,
                                    style:
                                        const TextStyle(fontSize: 22))),
                          ),
                          title: Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          subtitle: Text('${p.category} · per ${p.unit}',
                              style: const TextStyle(
                                  color: Color(0xFF888888),
                                  fontSize: 11)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₱${p.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE8572A),
                                      fontSize: 15)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      _stockColor(p).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  p.isOutOfStock
                                      ? 'OUT'
                                      : '${p.stock} ${p.unit}',
                                  style: TextStyle(
                                      color: _stockColor(p),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showAddEditDialog(product: p),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
