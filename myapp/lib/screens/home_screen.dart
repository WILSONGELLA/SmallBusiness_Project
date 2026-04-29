import 'package:flutter/material.dart';
import '../models/app_state.dart';
import 'inventory_screen.dart';
import 'customers_screen.dart';
import 'transactions_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _inventoryCategory = 'All';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _drawerSearchController = TextEditingController();
  String _drawerSearchQuery = '';

  static const Map<String, String> _categoryEmojis = {
    'All': '🗂️',
    'Instant Noodles': '🍜',
    'Beverages': '☕',
    'Biscuits': '🍪',
    'Dairy': '🥛',
    'Snacks': '🍿',
    'Household': '🧺',
    'Tobacco': '🚬',
    'Condiments': '🍶',
  };

  @override
  void dispose() {
    _drawerSearchController.dispose();
    super.dispose();
  }

  String _emojiFor(String cat) => _categoryEmojis[cat] ?? '📦';

  List<String> get _allCategories {
    final cats = AppData.sampleProducts.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  Map<String, int> get _categoryCounts {
    final counts = <String, int>{};
    for (final p in AppData.sampleProducts) {
      counts[p.category] = (counts[p.category] ?? 0) + 1;
    }
    counts['All'] = AppData.sampleProducts.length;
    return counts;
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8572A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, log out'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final counts = _categoryCounts;
    final categories = _allCategories;
    final outOfStock =
        AppData.sampleProducts.where((p) => p.isOutOfStock).length;
    final lowStock = AppData.sampleProducts
        .where((p) => p.isLowStock && !p.isOutOfStock)
        .length;

    return Drawer(
      backgroundColor: const Color(0xFFFFF8F5),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE8572A), Color(0xFFFF8C5A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Center(
                      child: Text('📦', style: TextStyle(fontSize: 26))),
                ),
                const SizedBox(height: 14),
                const Text('Products',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Georgia')),
                const SizedBox(height: 4),
                Text(
                    '${AppData.sampleProducts.length} items in inventory',
                    style:
                        const TextStyle(color: Color(0xFFFFD4C2), fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (outOfStock > 0) ...[
                      _badge('$outOfStock Out of Stock',
                          const Color(0xFFFFEBEB), const Color(0xFFE53935)),
                      const SizedBox(width: 6),
                    ],
                    if (lowStock > 0)
                      _badge('$lowStock Low Stock', const Color(0xFFFFF3E0),
                          const Color(0xFFF57C00)),
                    if (outOfStock == 0 && lowStock == 0)
                      _badge('All Good ✓', const Color(0xFFE8F5EE),
                          const Color(0xFF2D6A4F)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Row(
              children: [
                const Text('CATEGORIES',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Color(0xFFAAAAAA))),
                const Spacer(),
                Text('${categories.length - 1} categories',
                    style:
                        const TextStyle(fontSize: 10, color: Color(0xFFCCCCCC))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _drawerSearchController,
              onChanged: (val) => setState(
                  () => _drawerSearchQuery = val.trim().toLowerCase()),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search categories…',
                hintStyle: const TextStyle(
                    color: Color(0xFFCCCCCC), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: Color(0xFFAAAAAA)),
                suffixIcon: _drawerSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 16, color: Color(0xFFAAAAAA)),
                        onPressed: () {
                          _drawerSearchController.clear();
                          setState(() => _drawerSearchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF0EDE9),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFE8572A), width: 1.5)),
              ),
            ),
          ),
          Expanded(
            child: Builder(builder: (_) {
              final filtered = _drawerSearchQuery.isEmpty
                  ? categories
                  : categories
                      .where((c) => c.toLowerCase().contains(_drawerSearchQuery))
                      .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔍', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(
                        'No category found\nfor "$_drawerSearchQuery"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFFAAAAAA), fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final cat = filtered[i];
                  final isSelected = cat == _inventoryCategory;
                  final count = counts[cat] ?? 0;
                  final originalIndex = categories.indexOf(cat);

                  if (_drawerSearchQuery.isEmpty && originalIndex == 1) {
                    return Column(
                      children: [
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Divider(
                              height: 1, color: Color(0xFFEEECE8)),
                        ),
                        _categoryTile(
                            cat: cat,
                            emoji: _emojiFor(cat),
                            count: count,
                            isSelected: isSelected),
                      ],
                    );
                  }
                  return _categoryTile(
                      cat: cat,
                      emoji: _emojiFor(cat),
                      count: count,
                      isSelected: isSelected);
                },
              );
            }),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEEECE8)))),
            child: Column(
              children: [
                _actionTile(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Add New Product',
                  color: const Color(0xFF2D6A4F),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 1);
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tap the + button to add a new product'),
                            backgroundColor: Color(0xFF2D6A4F),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                _actionTile(
                  icon: Icons.logout_rounded,
                  label: 'Log Out',
                  color: const Color(0xFFE53935),
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryTile({
    required String cat,
    required String emoji,
    required int count,
    required bool isSelected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8572A) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.22)
                : const Color(0xFFFFF0EB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
        ),
        title: Text(
          cat,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF333333),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.25)
                : const Color(0xFFEEECE8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF888888),
            ),
          ),
        ),
        onTap: () {
          setState(() {
            _inventoryCategory = cat;
            _selectedIndex = 1;
            _drawerSearchQuery = '';
            _drawerSearchController.clear();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: TextStyle(
                color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
      );

  @override
  Widget build(BuildContext context) {
    final labels = ['Dashboard', 'Inventory', 'Customers', 'Transactions'];
    final tabIcons = [
      Icons.dashboard_outlined,
      Icons.inventory_2_outlined,
      Icons.people_outline,
      Icons.receipt_long_outlined,
    ];
    final activeTabIcons = [
      Icons.dashboard,
      Icons.inventory_2,
      Icons.people,
      Icons.receipt_long,
    ];
    final isInventory = _selectedIndex == 1;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFFF8F5),
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8572A),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: isInventory
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Categories',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        title: isInventory
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Inventory',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'Georgia',
                          color: Colors.white)),
                  Text(
                    _inventoryCategory == 'All'
                        ? 'All products'
                        : '${_emojiFor(_inventoryCategory)} $_inventoryCategory',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFFD4C2),
                        fontWeight: FontWeight.normal),
                  ),
                ],
              )
            : Row(
                children: [
                  const Text('🏪 ', style: TextStyle(fontSize: 20)),
                  Text(
                    labels[_selectedIndex],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        fontFamily: 'Georgia'),
                  ),
                ],
              ),
        actions: [
          if (isInventory)
            GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_list_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _inventoryCategory == 'All'
                          ? 'Filter'
                          : _inventoryCategory.split(' ').first,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Log out',
              onPressed: _logout,
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardTab(onGoToTransactions: () => setState(() => _selectedIndex = 3)),
          InventoryScreen(initialCategory: _inventoryCategory),
          const CustomersScreen(),
          TransactionsScreen(key: const ValueKey('txn')),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -4))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() {
            _selectedIndex = i;
            if (i != 1) _inventoryCategory = 'All';
          }),
          selectedItemColor: const Color(0xFFE8572A),
          unselectedItemColor: const Color(0xFFAAAAAA),
          backgroundColor: Colors.white,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: List.generate(
            4,
            (i) => BottomNavigationBarItem(
              icon: Icon(tabIcons[i]),
              activeIcon: Icon(activeTabIcons[i]),
              label: labels[i],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── DASHBOARD TAB ────────────────────────────────────────────────────────────

class DashboardTab extends StatelessWidget {
  final VoidCallback onGoToTransactions;
  const DashboardTab({super.key, required this.onGoToTransactions});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final products = store.products;
    final customers = store.customers;
    final lowStock =
        products.where((p) => p.isLowStock && !p.isOutOfStock).toList();
    final outOfStock = products.where((p) => p.isOutOfStock).toList();
    final totalValue =
        products.fold(0.0, (s, p) => s + p.price * p.stock);
    final avidCount = customers.where((c) => c.isAvid).length;
    final user = store.currentUser;
    final businessName = user?.businessName ?? "Aling's Sari-Sari Store";
    final firstName =
        user?.fullName.split(' ').first ?? 'Aling';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8572A), Color(0xFFFF8C5A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good day, $firstName! 👋',
                    style: const TextStyle(
                        color: Color(0xFFFFD4C2), fontSize: 13)),
                const SizedBox(height: 4),
                Text(businessName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _miniStat('₱${totalValue.toStringAsFixed(0)}',
                        'Stock Value'),
                    const SizedBox(width: 20),
                    _miniStat('${products.length}', 'Products'),
                    const SizedBox(width: 20),
                    _miniStat('$avidCount', 'Top Customers'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Today's sales quick card
          GestureDetector(
            onTap: onGoToTransactions,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                        child: Text('💰', style: TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Today's Sales",
                            style: TextStyle(
                                color: Color(0xFFAAAAAA), fontSize: 11)),
                        Text('₱${store.totalSalesToday.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Transactions',
                          style: TextStyle(
                              color: Color(0xFFAAAAAA), fontSize: 11)),
                      Text('${store.transactionsToday}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF888888)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Alerts
          if (outOfStock.isNotEmpty) ...[
            _alertCard(
                icon: Icons.error_outline,
                color: const Color(0xFFE53935),
                bg: const Color(0xFFFFEBEB),
                title: '${outOfStock.length} item(s) are OUT OF STOCK!',
                subtitle:
                    outOfStock.map((p) => '${p.emoji} ${p.name}').join(', ')),
            const SizedBox(height: 10),
          ],
          if (lowStock.isNotEmpty) ...[
            _alertCard(
                icon: Icons.warning_amber_outlined,
                color: const Color(0xFFF57C00),
                bg: const Color(0xFFFFF3E0),
                title: '${lowStock.length} item(s) are running low',
                subtitle: lowStock
                    .map((p) => '${p.emoji} ${p.name} (${p.stock} left)')
                    .join(', ')),
            const SizedBox(height: 20),
          ],

          // Stat cards
          Row(
            children: [
              Expanded(
                  child: _statCard('📦', '${products.length}', 'Products',
                      const Color(0xFF2D6A4F))),
              const SizedBox(width: 12),
              Expanded(
                  child: _statCard('⚠️', '${lowStock.length}', 'Low Stock',
                      const Color(0xFFF57C00))),
              const SizedBox(width: 12),
              Expanded(
                  child: _statCard('❌', '${outOfStock.length}', 'Out of Stock',
                      const Color(0xFFE53935))),
            ],
          ),
          const SizedBox(height: 20),

          const Text('🌟 Top Customers',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          ...customers
              .where((c) => c.isAvid)
              .take(3)
              .map((c) => _customerTile(c)),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFFFFD4C2), fontSize: 11)),
        ],
      );

  Widget _alertCard({
    required IconData icon,
    required Color color,
    required Color bg,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style:
                      TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))
          ]),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _customerTile(Customer c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))
          ]),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: c.tierColor.withOpacity(0.15),
            child: Text(c.name[0],
                style: TextStyle(
                    color: c.tierColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                  '${c.purchaseCount} purchases · ₱${c.totalSpent.toStringAsFixed(0)} total',
                  style: const TextStyle(
                      color: Color(0xFF888888), fontSize: 11)),
            ],
          )),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: c.tierColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text('${c.discountRate.toInt()}% off',
                style: TextStyle(
                    color: c.tierColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
