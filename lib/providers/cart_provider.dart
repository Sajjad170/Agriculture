import 'package:flutter/foundation.dart';

class CartItem {
  final int id;
  final String name;
  final double price;
  final String unit;
  final String type;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.type,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'unit': unit,
    'type': type,
    'qty': quantity,
  };
}

class CartProvider extends ChangeNotifier {
  static CartProvider? _instance;
  static CartProvider get instance => _instance ??= CartProvider._();
  CartProvider._();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get total => _items.fold(0, (sum, item) => sum + item.price * item.quantity);

  void addItem(Map<String, dynamic> product) {
    final id = product['id'] as int;
    final existing = _items.where((i) => i.id == id).firstOrNull;
    if (existing != null) {
      existing.quantity += 1;
    } else {
      _items.add(CartItem(
        id: id,
        name: product['name'] ?? '',
        price: (product['price'] as num).toDouble(),
        unit: product['unit'] ?? 'unit',
        type: product['type'] ?? '',
      ));
    }
    notifyListeners();
  }

  void removeItem(int id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void updateQuantity(int id, int delta) {
    final item = _items.where((i) => i.id == id).firstOrNull;
    if (item == null) return;
    final newQty = item.quantity + delta;
    if (newQty <= 0) {
      _items.remove(item);
    } else {
      item.quantity = newQty;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toOrderItems() => _items.map((i) => i.toJson()).toList();
}
