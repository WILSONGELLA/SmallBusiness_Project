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

  List<String> get categories => ['All', ...AppStore.instance.categories];

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

  void _showAddEditDialog({Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ProductFormSheet(
        product: product,
        initialCategory: _selectedCategory == 'All' ? '' : _selectedCategory,
        onSaved: (saved) {
          setState(() {
            if (product == null) {
              _products.add(saved);
              AppStore.instance.products.add(saved);
            }
            AppStore.instance.refreshData();
          });
          _showSuccessSnack(product == null
              ? '✅ "${saved.name}" has been added!'
              : '✅ Product updated successfully!');
        },
        onDeleted: product == null
            ? null
            : () {
                setState(() {
                  _products.removeWhere((p) => p.id == product.id);
                  AppStore.instance.products
                      .removeWhere((p) => p.id == product.id);
                  AppStore.instance.refreshData();
                });
                _showSuccessSnack('🗑️ "${product.name}" has been deleted.',
                    color: const Color(0xFFE53935));
              },
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
      duration: const Duration(seconds: 2),
    ));
  }

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
          // ── Search + category chips ──────────────────────────────────
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
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
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

          // ── Active filter banner ─────────────────────────────────────
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

          // ── Product list ─────────────────────────────────────────────
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📭', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        const Text('No products found',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 14)),
                        if (_selectedCategory != 'All') ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () =>
                                setState(() => _selectedCategory = 'All'),
                            child: const Text('View all',
                                style:
                                    TextStyle(color: Color(0xFFE8572A))),
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
                    padding:
                        const EdgeInsets.fromLTRB(12, 12, 12, 90),
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
                                    style: const TextStyle(
                                        fontSize: 22))),
                          ),
                          title: Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          subtitle: Text(
                              '${p.category} · per ${p.unit}',
                              style: const TextStyle(
                                  color: Color(0xFF888888),
                                  fontSize: 11)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
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
                              if (p.hasCaseSize) ...[
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2D6A4F)
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${p.caseSize}/case',
                                    style: const TextStyle(
                                        color: Color(0xFF2D6A4F),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
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

// ─── PRODUCT FORM SHEET (StatefulWidget) ─────────────────────────────────────

class _ProductFormSheet extends StatefulWidget {
  final Product? product;
  final String initialCategory;
  final void Function(Product) onSaved;
  final VoidCallback? onDeleted;

  const _ProductFormSheet({
    required this.product,
    required this.initialCategory,
    required this.onSaved,
    this.onDeleted,
  });

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _emojiCtrl;
  late final TextEditingController _caseSizeCtrl;

  late String _selectedCategory;
  late String _selectedUnit;
  bool _showCategoryError = false;

  static const List<String> _unitPresets = [
    'pack', 'sachet', 'bottle', 'can', 'piece',
    'case', 'box', 'kilo', 'liter', 'dozen', 'bundle', 'tray',
  ];

  bool get _isBeverage =>
      _selectedCategory.toLowerCase().contains('beverage');

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl =
        TextEditingController(text: p != null ? p.price.toString() : '');
    _stockCtrl =
        TextEditingController(text: p != null ? p.stock.toString() : '');
    _emojiCtrl = TextEditingController(text: p?.emoji ?? '📦');
    _caseSizeCtrl = TextEditingController(
        text: (p != null && p.caseSize > 0) ? p.caseSize.toString() : '');
    _selectedCategory = p?.category ?? widget.initialCategory;
    _selectedUnit = p?.unit ?? 'pack';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _emojiCtrl.dispose();
    _caseSizeCtrl.dispose();
    super.dispose();
  }

  // ── Category picker ────────────────────────────────────────────────────────
  Future<void> _pickCategory() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _PickerDialog(
        title: 'Category',
        items: AppStore.instance.categories,
        selected: _selectedCategory,
        onAddNew: (name) {
          AppStore.instance.addCategory(name);
          return name;
        },
        addNewLabel: '+ New Category',
        addNewHint: 'e.g. Personal Care',
      ),
    );
    if (result != null) {
      setState(() {
        _selectedCategory = result;
        _showCategoryError = false;
      });
    }
  }

  // ── Unit picker ────────────────────────────────────────────────────────────
  Future<void> _pickUnit() async {
    final allUnits = List<String>.from(_unitPresets)
      ..addAll(AppStore.instance.customUnits
          .where((u) => !_unitPresets.contains(u)));
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _PickerDialog(
        title: 'Unit',
        items: allUnits,
        selected: _selectedUnit,
        onAddNew: (name) {
          AppStore.instance.addCustomUnit(name);
          return name;
        },
        addNewLabel: '+ New Unit',
        addNewHint: 'e.g. bundle, tray, sack…',
      ),
    );
    if (result != null) setState(() => _selectedUnit = result);
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  void _save() {
    if (_selectedCategory.isEmpty) {
      setState(() => _showCategoryError = true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final p = widget.product;
    if (p == null) {
      final newProduct = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameCtrl.text.trim(),
        category: _selectedCategory,
        price: double.parse(_priceCtrl.text.trim()),
        stock: int.parse(_stockCtrl.text.trim()),
        unit: _selectedUnit,
        emoji:
            _emojiCtrl.text.trim().isEmpty ? '📦' : _emojiCtrl.text.trim(),
        caseSize: int.tryParse(_caseSizeCtrl.text.trim()) ?? 0,
      );
      Navigator.pop(context);
      widget.onSaved(newProduct);
    } else {
      p.name = _nameCtrl.text.trim();
      p.category = _selectedCategory;
      p.price = double.parse(_priceCtrl.text.trim());
      p.stock = int.parse(_stockCtrl.text.trim());
      p.unit = _selectedUnit;
      p.emoji =
          _emojiCtrl.text.trim().isEmpty ? '📦' : _emojiCtrl.text.trim();
      p.caseSize = int.tryParse(_caseSizeCtrl.text.trim()) ?? 0;
      Navigator.pop(context);
      widget.onSaved(p);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete ${_emojiCtrl.text} ${_nameCtrl.text}?',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('This cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: const Text('Delete'),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              widget.onDeleted?.call();
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

  Widget _selectorButton({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool hasError = false,
  }) {
    final hasValue = value.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(10),
          border: hasError
              ? Border.all(color: const Color(0xFFE53935), width: 1.5)
              : hasValue
                  ? Border.all(
                      color:
                          const Color(0xFFE8572A).withOpacity(0.5),
                      width: 1.5)
                  : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: hasError
                              ? const Color(0xFFE53935)
                              : const Color(0xFF888888))),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? value : 'Tap to select',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: hasValue
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: hasError
                            ? const Color(0xFFE53935)
                            : hasValue
                                ? const Color(0xFF1A1A2E)
                                : const Color(0xFFAAAAAA)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded,
                size: 20,
                color: hasError
                    ? const Color(0xFFE53935)
                    : const Color(0xFFAAAAAA)),
          ],
        ),
      ),
    );
  }

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

              // Title + delete
              Row(
                children: [
                  Text(
                    widget.product == null
                        ? '➕ New Product'
                        : '✏️ Edit Product',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (widget.product != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFE53935)),
                      tooltip: 'Delete',
                      onPressed: _confirmDelete,
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
                      controller: _emojiCtrl,
                      decoration: _inputDeco('Emoji'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDeco('Product name *'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
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
                      controller: _priceCtrl,
                      decoration: _inputDeco('Price (₱) *'),
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Enter a price';
                        if (double.tryParse(v.trim()) == null)
                          return 'Not a valid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: _inputDeco('Stock Qty *').copyWith(
                        suffixIcon: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() {
                                _stockCtrl.text =
                                    ((int.tryParse(_stockCtrl.text) ??
                                                0) +
                                            1)
                                        .toString();
                              }),
                              child: const Icon(Icons.arrow_drop_up_rounded,
                                  size: 20, color: Color(0xFF888888)),
                            ),
                            GestureDetector(
                              onTap: () => setState(() {
                                final cur =
                                    int.tryParse(_stockCtrl.text) ?? 0;
                                if (cur > 0)
                                  _stockCtrl.text = (cur - 1).toString();
                              }),
                              child: const Icon(
                                  Icons.arrow_drop_down_rounded,
                                  size: 20,
                                  color: Color(0xFF888888)),
                            ),
                          ],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Enter stock qty';
                        if (int.tryParse(v.trim()) == null)
                          return 'Whole number only';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category + Unit — tap-to-pick buttons
              Row(
                children: [
                  Expanded(
                    child: _selectorButton(
                      label: 'Category *',
                      value: _selectedCategory,
                      onTap: _pickCategory,
                      hasError: _showCategoryError,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _selectorButton(
                      label: 'Unit *',
                      value: _selectedUnit,
                      onTap: _pickUnit,
                    ),
                  ),
                ],
              ),
              if (_showCategoryError)
                const Padding(
                  padding: EdgeInsets.only(top: 4, left: 4),
                  child: Text('Category is required',
                      style: TextStyle(
                          color: Color(0xFFE53935), fontSize: 11)),
                ),
              const SizedBox(height: 12),

              // Case size (beverages only)
              if (_isBeverage) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            const Color(0xFF2D6A4F).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 14, color: Color(0xFF2D6A4F)),
                          SizedBox(width: 6),
                          Text('Beverage Case Settings',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D6A4F))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _caseSizeCtrl,
                        decoration: _inputDeco('Bottles per Case')
                            .copyWith(
                          hintText: 'e.g. 24',
                          hintStyle: const TextStyle(
                              fontSize: 11, color: Color(0xFFBBBBBB)),
                          helperText:
                              'Lets customers buy a full case at once',
                          helperStyle: const TextStyle(fontSize: 10),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            final n = int.tryParse(v.trim());
                            if (n == null || n < 2)
                              return 'Enter a whole number ≥ 2';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: Icon(
                      widget.product == null
                          ? Icons.add_rounded
                          : Icons.save_rounded,
                      size: 18),
                  label: Text(
                    widget.product == null ? 'Save Product' : 'Update',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
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

// ─── REUSABLE PICKER DIALOG ───────────────────────────────────────────────────

class _PickerDialog extends StatefulWidget {
  final String title;
  final List<String> items;
  final String selected;
  final String Function(String name) onAddNew;
  final String addNewLabel;
  final String addNewHint;

  const _PickerDialog({
    required this.title,
    required this.items,
    required this.selected,
    required this.onAddNew,
    required this.addNewLabel,
    required this.addNewHint,
  });

  @override
  State<_PickerDialog> createState() => _PickerDialogState();
}

class _PickerDialogState extends State<_PickerDialog> {
  late List<String> _items;
  late String _selected;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    _selected = widget.selected;
  }

  Future<void> _addNew() async {
    final ctrl = TextEditingController();
    final newName = await showDialog<String>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(widget.addNewLabel,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: widget.addNewHint,
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFFE8572A), width: 1.5)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dCtx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8572A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final saved = widget.onAddNew(newName);
      setState(() {
        if (!_items.contains(saved)) _items.add(saved);
        _selected = saved;
      });
      // Pop the picker dialog with the new value immediately
      if (mounted) Navigator.pop(context, saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Select ${widget.title}',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16)),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final item = _items[i];
                  final isSel = item == _selected;
                  return ListTile(
                    dense: true,
                    title: Text(item,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSel
                                ? const Color(0xFFE8572A)
                                : const Color(0xFF1A1A2E))),
                    trailing: isSel
                        ? const Icon(Icons.check_rounded,
                            color: Color(0xFFE8572A), size: 18)
                        : null,
                    onTap: () => Navigator.pop(context, item),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline_rounded,
                  color: Color(0xFFE8572A), size: 20),
              title: Text(widget.addNewLabel,
                  style: const TextStyle(
                      color: Color(0xFFE8572A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              onTap: _addNew,
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