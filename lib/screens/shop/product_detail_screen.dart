import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/cart_provider.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  final _cart = CartProvider.instance;

  bool get isPesticide => widget.product['type'] == 'pesticide';
  bool get isSeed => widget.product['type'] == 'seed';

  Color get primaryColor => isPesticide ? Colors.red.shade600 : isSeed ? Colors.amber.shade600 : Colors.green.shade600;
  List<Color> get gradColors => isPesticide ? [Colors.red.shade600, Colors.red.shade400] : isSeed ? [Colors.amber.shade600, Colors.amber.shade400] : [Colors.green.shade700, Colors.green.shade500];
  String get emoji => isPesticide ? '🧪' : isSeed ? '🌱' : '🌿';

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final price = (p['price'] as num).toDouble();
    final total = price * _qty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: primaryColor,
            leading: IconButton(
              icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20)),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Stack(children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                ),
                if (_cart.itemCount > 0)
                  Positioned(right: 6, top: 6, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Text('${_cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))),
              ]),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradColors)),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 90)).animate().scale(begin: const Offset(0.5, 0.5)).fadeIn()),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(p['type'] ?? '', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 12)),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 10),
                    Text(p['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 6),
                    Text('PKR ${price.toStringAsFixed(0)} / ${p['unit'] ?? 'unit'}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: primaryColor)).animate().fadeIn(delay: 200.ms),

                    if ((p['description'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionCard(title: '📋 Description', content: p['description'], delay: 250),
                    ],
                    if ((p['crop_compatibility'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _SectionCard(title: '🌾 Crop Compatibility', content: p['crop_compatibility'], delay: 300, iconColor: Colors.green),
                    ],
                    if ((p['usage_guide'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _SectionCard(title: '📖 Usage Guide', content: p['usage_guide'], delay: 350, iconColor: Colors.blue),
                    ],
                    if ((p['effects'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _SectionCard(title: '⚠️ Effects & Warnings', content: p['effects'], delay: 400, iconColor: Colors.orange),
                    ],

                    const SizedBox(height: 20),
                    // Quantity selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          Row(children: [
                            _QtyBtn(icon: Icons.remove_rounded, onTap: () { if (_qty > 1) setState(() => _qty--); }),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: Text('$_qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                            _QtyBtn(icon: Icons.add_rounded, onTap: () => setState(() => _qty++)),
                          ]),
                        ],
                      ),
                    ).animate().fadeIn(delay: 450.ms),

                    const SizedBox(height: 24),
                    // Add to cart button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          for (int i = 0; i < _qty; i++) _cart.addItem(widget.product);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('${p['name']} (×$_qty) added to cart ✓'),
                            backgroundColor: Colors.green.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                          shadowColor: primaryColor.withOpacity(0.4),
                        ),
                        child: Text('Add to Cart — PKR ${total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? content;
  final int delay;
  final Color? iconColor;
  const _SectionCard({required this.title, this.content, this.delay = 0, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: (iconColor ?? Colors.green).withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: (iconColor ?? Colors.green).withOpacity(0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: iconColor ?? Colors.green.shade700, fontSize: 13)),
          const SizedBox(height: 5),
          Text(content ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5)),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: -0.05);
  }
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
        width: 36, height: 36,
        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade200)),
        child: Icon(icon, color: Colors.green.shade700, size: 20),
      ),
    );
  }
}
