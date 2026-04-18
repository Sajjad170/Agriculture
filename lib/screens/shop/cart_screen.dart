import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/cart_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cart = CartProvider.instance;

  @override
  void initState() {
    super.initState();
    _cart.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final items = _cart.items;
    final total = _cart.total;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Cart (${_cart.itemCount})', style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade700,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () { _cart.clear(); setState(() {}); },
              child: Text('Clear', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: items.isEmpty ? _buildEmpty() : _buildCart(items, total),
      bottomNavigationBar: items.isEmpty ? null : Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total (${_cart.itemCount} items)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('PKR ${total.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.green.shade700)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Proceed to Checkout →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCart(List<CartItem> items, double total) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final emoji = item.type == 'pesticide' ? '🧪' : item.type == 'seed' ? '🌱' : '🌿';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('PKR ${item.price.toStringAsFixed(0)} / ${item.unit}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(children: [
                        _QtyBtn(icon: Icons.remove_rounded, onTap: () { _cart.updateQuantity(item.id, -1); setState(() {}); }),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                        _QtyBtn(icon: Icons.add_rounded, onTap: () { _cart.updateQuantity(item.id, 1); setState(() {}); }),
                      ]),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () { _cart.removeItem(item.id); setState(() {}); },
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    ),
                    const SizedBox(height: 10),
                    Text('PKR ${(item.price * item.quantity).toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.green.shade700, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 60));
      },
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🛒', style: TextStyle(fontSize: 72)),
      const SizedBox(height: 16),
      const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Add products to get started', style: TextStyle(color: Colors.grey.shade500)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Browse Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    ]),
  );
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
        child: Icon(icon, color: Colors.green.shade700, size: 18),
      ),
    );
  }
}
