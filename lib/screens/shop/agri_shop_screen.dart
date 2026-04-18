import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/backend_service.dart';
import '../../providers/cart_provider.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';

class AgriShopScreen extends StatefulWidget {
  const AgriShopScreen({super.key});

  @override
  State<AgriShopScreen> createState() => _AgriShopScreenState();
}

class _AgriShopScreenState extends State<AgriShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _selectedType = 'all';
  final _cart = CartProvider.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _setFilter(_tabController.index);
    });
    _loadProducts();
    _cart.addListener(() => setState(() {}));
  }

  void _setFilter(int index) {
    final types = ['all', 'pesticide', 'fertilizer', 'seed'];
    _selectedType = types[index];
    _applyFilter();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    final products = await BackendService.instance.getProducts();
    if (mounted) {
      setState(() {
        _allProducts = products;
        _filtered = products;
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _allProducts.where((p) {
        final matchType = _selectedType == 'all' || p['type'] == _selectedType;
        final matchSearch = q.isEmpty || (p['name'] ?? '').toLowerCase().contains(q) || (p['crop_compatibility'] ?? '').toLowerCase().contains(q);
        return matchType && matchSearch;
      }).toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartCount = _cart.itemCount;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 130,
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green.shade700, Colors.green.shade500],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('🌾 Agri Shop', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 28),
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                                ),
                                if (cartCount > 0)
                                  Positioned(
                                    right: 6, top: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))]),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => _applyFilter(),
                            decoration: InputDecoration(
                              hintText: 'Search pesticides, fertilizers, seeds...',
                              prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.green.shade600,
                  labelColor: Colors.green.shade700,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: '🧪 Sprays'),
                    Tab(text: '🌿 Fertilizers'),
                    Tab(text: '🌱 Seeds'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : _filtered.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    color: Colors.green,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(14),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) => _ProductCard(
                        product: _filtered[i],
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: _filtered[i]))),
                        onAddToCart: () {
                          _cart.addItem(_filtered[i]);
                          _showAddedToast(_filtered[i]['name']);
                        },
                      ).animate().fadeIn(delay: Duration(milliseconds: i * 60)).slideY(begin: 0.15),
                    ),
                  ),
      ),
    );
  }

  void _showAddedToast(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name added to cart ✓'),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('📦', style: TextStyle(fontSize: 56)),
      const SizedBox(height: 12),
      Text('No products found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
      const SizedBox(height: 8),
      TextButton(onPressed: _loadProducts, child: const Text('Refresh', style: TextStyle(color: Colors.green))),
    ]),
  );
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const _ProductCard({required this.product, required this.onTap, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final isPesticide = product['type'] == 'pesticide';
    final isSeed = product['type'] == 'seed';
    final emoji = isPesticide ? '🧪' : isSeed ? '🌱' : '🌿';
    final gradColors = isPesticide
        ? [Colors.red.shade50, Colors.red.shade100]
        : isSeed
            ? [Colors.amber.shade50, Colors.amber.shade100]
            : [Colors.green.shade50, Colors.green.shade100];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradColors),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 44))),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPesticide ? Colors.red.shade50 : isSeed ? Colors.amber.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product['type'] ?? '',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isPesticide ? Colors.red.shade700 : isSeed ? Colors.amber.shade700 : Colors.green.shade700),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(product['crop_compatibility'] ?? '', style: TextStyle(fontSize: 10, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PKR ${(product['price'] as num).toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.green.shade700)),
                            Text('/${product['unit'] ?? 'unit'}', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                          ],
                        ),
                        GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.green.shade500, Colors.green.shade700]),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(color: Colors.green.shade200, blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
