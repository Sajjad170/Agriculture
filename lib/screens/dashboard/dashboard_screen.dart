import 'package:hugeicons/hugeicons.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../shop/agri_shop_screen.dart';
import '../shop/cart_screen.dart';
import '../market/pakistan_market_screen.dart';
import '../ai/ai_farming_screen.dart';
import '../orders/my_orders_screen.dart';
import 'home_tab.dart';
import 'disease_detection_tab.dart';
import 'profile_tab.dart';
import 'agri_bot.dart';
import '../../providers/cart_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final _cart = CartProvider.instance;

  final List<Widget> _tabs = [
    const HomeTab(),
    const AgriShopScreen(),
    const DiseaseDetectionTab(),
    const PakistanMarketScreen(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _cart.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? theme.scaffoldBackgroundColor : Colors.white;
    final cartCount = _cart.itemCount;

    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 60.0,
        items: [
          SvgPicture.asset('assets/navbar/home.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
          Stack(
            children: [
              const Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
              if (cartCount > 0)
                Positioned(
                  right: 0, top: 0,
                  child: Container(
                    width: 14, height: 14,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Center(child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))),
                  ),
                ),
            ],
          ),
          SvgPicture.asset('assets/navbar/scanner.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
          SvgPicture.asset('assets/navbar/market.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
          SvgPicture.asset('assets/navbar/user.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
        ],
        color: theme.colorScheme.primary,
        buttonBackgroundColor: theme.colorScheme.primary,
        backgroundColor: backgroundColor,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: _onItemTapped,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'aiChatButton',
            mini: true,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIFarmingScreen())),
            backgroundColor: Colors.purple.shade600,
            child: const Icon(Icons.psychology_rounded, size: 22, color: Colors.white),
            tooltip: 'AI Assistant',
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'chatButton',
            mini: true,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartFarmAssistant())),
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(HugeIcons.strokeRoundedAiChat02, size: 22, color: Colors.white),
            tooltip: 'Farm Assistant',
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'moreButton',
            onPressed: _showQuickActionsMenu,
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(HugeIcons.strokeRoundedMore, size: 24, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showQuickActionsMenu() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Quick Actions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _QuickAction(icon: Icons.storefront_rounded, color: Colors.green, title: 'Shop Products', subtitle: 'Browse pesticides, fertilizers & seeds', onTap: () { Navigator.pop(context); setState(() => _selectedIndex = 1); }),
            _QuickAction(icon: Icons.shopping_cart_rounded, color: Colors.orange, title: 'View Cart', subtitle: 'Review cart & checkout', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())); }),
            _QuickAction(icon: Icons.psychology_rounded, color: Colors.purple, title: 'AI Farming Assistant', subtitle: 'Get smart crop recommendations', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AIFarmingScreen())); }),
            _QuickAction(icon: Icons.receipt_long_rounded, color: Colors.blue, title: 'My Orders', subtitle: 'Track your purchases', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen())); }),
            _QuickAction(icon: Icons.trending_up_rounded, color: Colors.teal, title: 'Market Rates', subtitle: 'Live Pakistan crop prices', onTap: () { Navigator.pop(context); setState(() => _selectedIndex = 3); }),
            _QuickAction(icon: HugeIcons.strokeRoundedSearchFocus, color: Colors.indigo, title: 'Scan Disease', subtitle: 'Detect crop diseases with camera', onTap: () { Navigator.pop(context); setState(() => _selectedIndex = 2); }),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 22, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      onTap: onTap,
    );
  }
}
