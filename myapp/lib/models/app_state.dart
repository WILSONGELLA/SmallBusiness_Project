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

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.unit,
    required this.emoji,
  });

  bool get isLowStock => stock <= 5;
  bool get isOutOfStock => stock == 0;
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

// ─── GLOBAL APP STORE ─────────────────────────────────────────────────────────
class AppStore {
  AppStore._();
  static final AppStore instance = AppStore._();

  // ── Accounts (starts with the demo account) ──────────────────────────────
  final List<UserAccount> accounts = [
    UserAccount(
      id: 'demo',
      username: 'aling',
      password: '1234',
      fullName: 'Aling Demo',
      businessName: "Aling's Sari-Sari Store",
      phone: '09171234567',
      email: 'aling@tindahan.ph',
    ),
  ];

  UserAccount? currentUser;

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
    currentUser = account;
    return account;
  }

  // ── Products ──────────────────────────────────────────────────────────────
  final List<Product> products = [
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
  ];

  // ── Customers ─────────────────────────────────────────────────────────────
  final List<Customer> customers = [
    Customer(id: '1', name: 'Aling Rosa Reyes', phone: '09171234567', purchaseCount: 45, totalSpent: 6200, isAvid: true, discountRate: 10, notes: 'Likes to buy on credit'),
    Customer(id: '2', name: 'Mang Bert Santos', phone: '09281234567', purchaseCount: 32, totalSpent: 3800, isAvid: true, discountRate: 5, notes: 'Pays always on time'),
    Customer(id: '3', name: 'Ate Nena Cruz', phone: '09351234567', purchaseCount: 18, totalSpent: 2100, isAvid: true, discountRate: 5),
    Customer(id: '4', name: 'Kuya Jun Dela Cruz', phone: '09461234567', purchaseCount: 8, totalSpent: 950, isAvid: false, discountRate: 0),
    Customer(id: '5', name: 'Lola Caring Mateo', phone: '09571234567', purchaseCount: 55, totalSpent: 7500, isAvid: true, discountRate: 15, notes: 'Give extra candy'),
    Customer(id: '6', name: 'Tita Cora Bautista', phone: '09681234567', purchaseCount: 12, totalSpent: 1400, isAvid: false, discountRate: 0),
  ];

  // ── Transactions ──────────────────────────────────────────────────────────
  final List<Transaction> transactions = [];

  void addTransaction(Transaction t) {
    transactions.insert(0, t);
    // deduct stock
    for (final item in t.items) {
      item.product.stock =
          (item.product.stock - item.quantity).clamp(0, 9999);
    }
    // update customer stats
    if (t.customer != null) {
      t.customer!.purchaseCount += 1;
      t.customer!.totalSpent += t.grandTotal;
    }
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
