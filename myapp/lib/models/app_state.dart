// Models for the TindaHan App
import 'package:flutter/material.dart';

// ─── USER ACCOUNT ─────────────────────────────────────────────────────────────
class UserAccount {
  final String id;
  String username;
  String password;
  String fullName;
  String businessName;
  String phone;
  String email;

  UserAccount({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.businessName,
    required this.phone,
    required this.email,
  });
}

// ─── PRODUCT ──────────────────────────────────────────────────────────────────
class Product {
  final String id;
  String name;
  String category;
  double price;
  int stock;
  String unit;
  String emoji;
  /// For beverages: how many individual units are in one case (0 = not applicable)
  int caseSize;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.unit,
    required this.emoji,
    this.caseSize = 0,
  });

  bool get isLowStock => stock <= 5;
  bool get isOutOfStock => stock == 0;
  bool get hasCaseSize => caseSize > 1;
}

// ─── CUSTOMER ─────────────────────────────────────────────────────────────────
class Customer {
  final String id;
  String name;
  String phone;
  int purchaseCount;
  double totalSpent;
  bool isAvid;
  double discountRate;
  String? notes;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.purchaseCount = 0,
    this.totalSpent = 0,
    this.isAvid = false,
    this.discountRate = 0,
    this.notes,
  });

  String get tier {
    if (totalSpent >= 5000) return 'Gold Member';
    if (totalSpent >= 2000) return 'Silver Member';
    if (purchaseCount >= 10) return 'Regular';
    return 'New Customer';
  }

  Color get tierColor {
    switch (tier) {
      case 'Gold Member':
        return const Color(0xFFD4AF37);
      case 'Silver Member':
        return const Color(0xFF9E9E9E);
      case 'Regular':
        return const Color(0xFF2D6A4F);
      default:
        return const Color(0xFF78909C);
    }
  }
}

// ─── TRANSACTION ──────────────────────────────────────────────────────────────
class ReceiptItem {
  final Product product;
  final int quantity;
  final double unitPrice;
  final double discountRate;

  ReceiptItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.discountRate = 0,
  });

  double get subtotal => unitPrice * quantity;
  double get discountAmount => subtotal * (discountRate / 100);
  double get total => subtotal - discountAmount;
}

class Transaction {
  final String id;
  final DateTime date;
  final List<ReceiptItem> items;
  final Customer? customer;
  final double discountRate;
  final String paymentMethod;
  final double amountPaid;

  Transaction({
    required this.id,
    required this.date,
    required this.items,
    this.customer,
    this.discountRate = 0,
    required this.paymentMethod,
    required this.amountPaid,
  });

  double get subtotal => items.fold(0, (s, i) => s + i.subtotal);
  double get discountAmount => subtotal * (discountRate / 100);
  double get grandTotal => subtotal - discountAmount;
  double get change => amountPaid - grandTotal;

  String get receiptNumber =>
      'TXN-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}-${id.substring(id.length - 4).toUpperCase()}';
}

// ─── RECEIVABLE (Accounts Receivable / Utang) ─────────────────────────────────
class Receivable {
  final String id;
  final String customerName;
  final String customerPhone;
  double amount;
  final DateTime dateCreated;
  DateTime? dueDate;
  bool isPaid;
  String? notes;
  final List<String> itemsSummary; // e.g. ['2x Lucky Me', '1x Bear Brand']

  Receivable({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    required this.dateCreated,
    this.dueDate,
    this.isPaid = false,
    this.notes,
    this.itemsSummary = const [],
  });

  bool get isOverdue =>
      !isPaid && dueDate != null && DateTime.now().isAfter(dueDate!);

  bool get isDueSoon {
    if (isPaid || dueDate == null) return false;
    final diff = dueDate!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 3;
  }
}


class UserData {
  final List<Product> products;
  final List<Customer> customers;
  final List<Transaction> transactions;
  final List<String> categories;
  final List<Receivable> receivables;
  final List<String> customUnits;

  UserData({
    List<Product>? products,
    List<Customer>? customers,
    List<Transaction>? transactions,
    List<String>? categories,
    List<Receivable>? receivables,
    List<String>? customUnits,
  })  : products = products ?? [],
        customers = customers ?? [],
        transactions = transactions ?? [],
        categories = categories ?? [],
        receivables = receivables ?? [],
        customUnits = customUnits ?? [];
}

// ─── GLOBAL APP STORE ─────────────────────────────────────────────────────────
class AppStore extends ChangeNotifier {
  AppStore._() {
    // Seed data only for the demo account
    _userDataMap[_demoAccount.id] = UserData(
      categories: [
        'Instant Noodles',
        'Beverages',
        'Biscuits',
        'Dairy',
        'Snacks',
        'Household',
        'Tobacco',
        'Condiments',
      ],
      products: [
        Product(id: '1', name: 'Lucky Me Pancit Canton', category: 'Instant Noodles', price: 15, stock: 48, unit: 'pack', emoji: '🍜'),
        Product(id: '2', name: 'Nescafe 3-in-1', category: 'Beverages', price: 8, stock: 120, unit: 'sachet', emoji: '☕'),
        Product(id: '3', name: 'Sky Flakes', category: 'Biscuits', price: 12, stock: 3, unit: 'pack', emoji: '🍪'),
        Product(id: '4', name: 'Bear Brand Milk', category: 'Dairy', price: 55, stock: 24, unit: 'can', emoji: '🥛'),
        Product(id: '5', name: 'Chippy', category: 'Snacks', price: 22, stock: 0, unit: 'pack', emoji: '🍿'),
        Product(id: '6', name: 'Tide Detergent', category: 'Household', price: 6, stock: 80, unit: 'sachet', emoji: '🧺'),
        Product(id: '7', name: 'San Miguel Beer', category: 'Beverages', price: 65, stock: 36, unit: 'bottle', emoji: '🍺'),
        Product(id: '8', name: 'Marlboro Red', category: 'Tobacco', price: 170, stock: 10, unit: 'pack', emoji: '🚬'),
        Product(id: '9', name: 'Coconut Vinegar', category: 'Condiments', price: 20, stock: 15, unit: 'bottle', emoji: '🍶'),
        Product(id: '10', name: 'Magic Sarap', category: 'Condiments', price: 5, stock: 60, unit: 'sachet', emoji: '✨'),
      ],
      customers: [
        Customer(id: '1', name: 'Aling Rosa Reyes', phone: '09171234567', purchaseCount: 45, totalSpent: 6200, isAvid: true, discountRate: 10, notes: 'Likes to buy on credit'),
        Customer(id: '2', name: 'Mang Bert Santos', phone: '09281234567', purchaseCount: 32, totalSpent: 3800, isAvid: true, discountRate: 5, notes: 'Pays always on time'),
        Customer(id: '3', name: 'Ate Nena Cruz', phone: '09351234567', purchaseCount: 18, totalSpent: 2100, isAvid: true, discountRate: 5),
        Customer(id: '4', name: 'Kuya Jun Dela Cruz', phone: '09461234567', purchaseCount: 8, totalSpent: 950, isAvid: false, discountRate: 0),
        Customer(id: '5', name: 'Lola Caring Mateo', phone: '09571234567', purchaseCount: 55, totalSpent: 7500, isAvid: true, discountRate: 15, notes: 'Give extra candy'),
        Customer(id: '6', name: 'Tita Cora Bautista', phone: '09681234567', purchaseCount: 12, totalSpent: 1400, isAvid: false, discountRate: 0),
      ],
    );
  }

  static final AppStore instance = AppStore._();

  // ── Accounts ──────────────────────────────────────────────────────────────
  static final UserAccount _demoAccount = UserAccount(
    id: 'demo',
    username: 'aling',
    password: '1234',
    fullName: 'Aling Demo',
    businessName: "Aling's Sari-Sari Store",
    phone: '09171234567',
    email: 'aling@tindahan.ph',
  );

  final List<UserAccount> accounts = [_demoAccount];

  UserAccount? currentUser;

  // ── Per-user data storage ─────────────────────────────────────────────────
  final Map<String, UserData> _userDataMap = {};

  /// Returns the data store for the currently logged-in user.
  UserData get _currentData {
    if (currentUser == null) return UserData();
    return _userDataMap.putIfAbsent(currentUser!.id, () => UserData());
  }

  // ── Convenience accessors ─────────────────────────────────────────────────
  List<Product> get products => _currentData.products;
  List<Customer> get customers => _currentData.customers;
  List<Transaction> get transactions => _currentData.transactions;
  List<Receivable> get receivables => _currentData.receivables;

  /// Sorted list of categories for the current user.
  List<String> get categories {
    final cats = List<String>.from(_currentData.categories);
    cats.sort();
    return cats;
  }

  // ── Receivables management ────────────────────────────────────────────────
  void addReceivable(Receivable r) {
    _currentData.receivables.insert(0, r);
    notifyListeners();
  }

  void markReceivablePaid(String id) {
    final idx = _currentData.receivables.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _currentData.receivables[idx].isPaid = true;
      notifyListeners();
    }
  }

  void deleteReceivable(String id) {
    _currentData.receivables.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  double get totalReceivables => _currentData.receivables
      .where((r) => !r.isPaid)
      .fold(0.0, (s, r) => s + r.amount);

  int get overdueReceivables =>
      _currentData.receivables.where((r) => r.isOverdue).length;

  // ── Category management ───────────────────────────────────────────────────

  /// Adds a new category. Returns false if it already exists (case-insensitive).
  bool addCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final already = _currentData.categories
        .any((c) => c.toLowerCase() == trimmed.toLowerCase());
    if (already) return false;
    _currentData.categories.add(trimmed);
    notifyListeners();
    return true;
  }

  /// Removes a category by name.
  void removeCategory(String name) {
    _currentData.categories.removeWhere((c) => c == name);
    notifyListeners();
  }

  // ── Custom unit management ────────────────────────────────────────────────

  List<String> get customUnits => _currentData.customUnits;

  /// Adds a custom unit. Returns the name if added, or the existing name if duplicate.
  String addCustomUnit(String name) {
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    final existing = _currentData.customUnits
        .firstWhere((u) => u.toLowerCase() == trimmed, orElse: () => '');
    if (existing.isNotEmpty) return existing;
    _currentData.customUnits.add(trimmed);
    notifyListeners();
    return trimmed;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  bool login(String username, String password) {
    final match = accounts.where(
      (a) =>
          a.username.toLowerCase() == username.toLowerCase() &&
          a.password == password,
    );
    if (match.isNotEmpty) {
      currentUser = match.first;
      return true;
    }
    return false;
  }

  UserAccount register({
    required String fullName,
    required String businessName,
    required String phone,
    required String email,
    required String password,
  }) {
    // username = first word of full name, lowercased
    String base = fullName.trim().split(' ').first.toLowerCase();
    String username = base;
    int suffix = 1;
    while (accounts.any((a) => a.username == username)) {
      username = '$base$suffix';
      suffix++;
    }

    final account = UserAccount(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      password: password,
      fullName: fullName,
      businessName: businessName,
      phone: phone,
      email: email,
    );
    accounts.add(account);

    // New users start with empty data — no seeded products, customers, or categories
    _userDataMap[account.id] = UserData();

    currentUser = account;
    return account;
  }

  // ── Transactions ──────────────────────────────────────────────────────────
  void addTransaction(Transaction t) {
    _currentData.transactions.insert(0, t);
    // Deduct stock
    for (final item in t.items) {
      item.product.stock =
          (item.product.stock - item.quantity).clamp(0, 9999);
    }
    // Update customer stats
    if (t.customer != null) {
      t.customer!.purchaseCount += 1;
      t.customer!.totalSpent += t.grandTotal;
    }
    notifyListeners();
  }

  // Public method to notify listeners of changes
  void refreshData() {
    notifyListeners();
  }

  double get totalSalesToday {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day)
        .fold(0.0, (s, t) => s + t.grandTotal);
  }

  int get transactionsToday {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day)
        .length;
  }
}

// Keep backward-compatible AppData alias so existing screens don't break
class AppData {
  static List<Product> get sampleProducts => AppStore.instance.products;
  static List<Customer> get sampleCustomers => AppStore.instance.customers;
}