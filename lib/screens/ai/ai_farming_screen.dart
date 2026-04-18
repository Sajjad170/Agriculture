import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/backend_service.dart';
import '../../providers/cart_provider.dart';

class AIFarmingScreen extends StatefulWidget {
  const AIFarmingScreen({super.key});

  @override
  State<AIFarmingScreen> createState() => _AIFarmingScreenState();
}

class _AIFarmingScreenState extends State<AIFarmingScreen> {
  String? _selectedCrop;
  final _problemCtrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  final _cart = CartProvider.instance;

  final List<Map<String, dynamic>> _crops = [
    {'name': 'Wheat', 'emoji': '🌾'},
    {'name': 'Rice', 'emoji': '🍚'},
    {'name': 'Cotton', 'emoji': '🪴'},
    {'name': 'Maize', 'emoji': '🌽'},
    {'name': 'Sugarcane', 'emoji': '🎋'},
    {'name': 'Vegetables', 'emoji': '🥦'},
    {'name': 'Fruit Trees', 'emoji': '🌳'},
    {'name': 'Sunflower', 'emoji': '🌻'},
  ];

  final List<String> _quickProblems = ['Yellow leaves', 'Aphids', 'Rust disease', 'Stem borer', 'Weed control', 'White fly', 'Bollworm', 'Leaf curl'];

  Future<void> _getRecommendation() async {
    if (_selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Please select a crop'), backgroundColor: Colors.orange.shade600, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }
    setState(() { _loading = true; _result = null; });
    final result = await BackendService.instance.getAIRecommendation(_selectedCrop!, _problemCtrl.text);
    if (mounted) setState(() { _result = result; _loading = false; });
  }

  @override
  void dispose() {
    _problemCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.purple.shade700, Colors.indigo.shade500]),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('🤖 AI Farming Assistant', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Smart crop recommendations powered by AI', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crop selection
                  _Card(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('🌱 Select Your Crop', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _crops.map((crop) {
                          final selected = _selectedCrop == crop['name'];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCrop = crop['name']),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? Colors.purple.shade600 : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: selected ? Colors.purple.shade600 : Colors.grey.shade200, width: 1.5),
                                boxShadow: selected ? [BoxShadow(color: Colors.purple.shade200, blurRadius: 8, offset: const Offset(0, 3))] : [],
                              ),
                              child: Text('${crop['emoji']} ${crop['name']}', style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.grey.shade700, fontSize: 13)),
                            ),
                          );
                        }).toList(),
                      ),
                    ]),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 12),

                  // Problem input
                  _Card(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('🐛 Describe the Problem', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 8),
                      Text('Quick select:', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: _quickProblems.map((p) => GestureDetector(
                          onTap: () => setState(() => _problemCtrl.text = p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
                            child: Text(p, style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w500)),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _problemCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Describe what you see: leaf color, spots, insects...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.purple.shade400, width: 1.5)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ]),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _getRecommendation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                        shadowColor: Colors.purple.shade200,
                      ),
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('🔍 Get AI Recommendation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  // Result
                  if (_result != null) ...[
                    const SizedBox(height: 16),
                    _buildResult(_result!),
                  ],

                  const SizedBox(height: 16),

                  // Tips
                  _buildTips(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(Map<String, dynamic> r) {
    final confidence = r['confidence'] ?? 'low';
    final confidenceColor = confidence == 'high' ? Colors.green.shade600 : confidence == 'medium' ? Colors.orange.shade600 : Colors.red.shade400;
    final tip = r['tip'] ?? '';
    final pesticide = r['pesticide'] as Map<String, dynamic>?;
    final fertilizer = r['fertilizer'] as Map<String, dynamic>?;

    return Column(
      children: [
        _Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: confidenceColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(confidence == 'high' ? Icons.verified_rounded : Icons.info_rounded, color: confidenceColor, size: 14),
                  const SizedBox(width: 5),
                  Text(confidence == 'high' ? 'High Confidence' : confidence == 'medium' ? 'Medium Confidence' : 'General Advice', style: TextStyle(color: confidenceColor, fontWeight: FontWeight.w700, fontSize: 12)),
                ]),
              ),
              const SizedBox(width: 8),
              Text('AI Result', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.grey.shade700)),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(child: Text(tip, style: TextStyle(color: Colors.green.shade800, fontSize: 13, height: 1.5))),
              ]),
            ),
          ]),
        ).animate().fadeIn().slideY(begin: 0.1),

        const SizedBox(height: 12),

        Row(children: [
          if (pesticide != null)
            Expanded(child: _ProductRecoCard(title: '🧪 Pesticide', product: pesticide, color: Colors.red.shade600, cart: _cart)),
          if (pesticide != null && fertilizer != null) const SizedBox(width: 10),
          if (fertilizer != null)
            Expanded(child: _ProductRecoCard(title: '🌿 Fertilizer', product: fertilizer, color: Colors.green.shade600, cart: _cart)),
        ]).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildTips() {
    final tips = [
      {'icon': '🌱', 'title': 'Soil Health', 'text': 'Test soil pH before each season. Optimal pH for wheat is 6.0-7.5'},
      {'icon': '💧', 'title': 'Water Management', 'text': 'Irrigate at tillering, jointing, flowering & grain filling stages'},
      {'icon': '📅', 'title': 'Timing', 'text': 'Apply fertilizer at recommended growth stages for maximum efficiency'},
      {'icon': '🌡️', 'title': 'Spraying Time', 'text': 'Spray pesticides in early morning or evening, never before rain'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('💡 General Farming Tips', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        ...tips.asMap().entries.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Row(children: [
            Text(e.value['icon']!, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.value['title']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 3),
              Text(e.value['text']!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4)),
            ])),
          ]),
        ).animate().fadeIn(delay: Duration(milliseconds: 400 + e.key * 80))),
      ],
    );
  }
}

class _ProductRecoCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> product;
  final Color color;
  final CartProvider cart;
  const _ProductRecoCard({required this.title, required this.product, required this.color, required this.cart});

  @override
  Widget build(BuildContext context) {
    final price = product['price'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))], border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color.withOpacity(0.8))),
        const SizedBox(height: 6),
        Text(product['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 2),
        const SizedBox(height: 4),
        if (price != null && price != 'See shop')
          Text('PKR ${(price as num).toStringAsFixed(0)}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 10),
        if (product['id'] != null)
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              cart.addItem(product);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product['name']} added to cart ✓'), backgroundColor: Colors.green.shade600, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 2)));
            },
            style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), minimumSize: const Size(0, 36)),
            child: const Text('+ Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          )),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 5))]),
      child: child,
    );
  }
}
