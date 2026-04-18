import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/backend_service.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      final orders = await BackendService.instance.getOrdersByEmail(user!.email!);
      if (mounted) setState(() { _orders = orders; _loading = false; });
    } else {
      if (mounted) setState(() { _orders = []; _loading = false; });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return Colors.blue.shade600;
      case 'shipped': return Colors.purple.shade600;
      case 'delivered': return Colors.green.shade600;
      case 'rejected': return Colors.red.shade600;
      default: return Colors.orange.shade600;
    }
  }

  String _statusEmoji(String status) {
    switch (status) {
      case 'approved': return '✅';
      case 'shipped': return '🚚';
      case 'delivered': return '📦';
      case 'rejected': return '❌';
      default: return '⏳';
    }
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'approved': return 'Order confirmed! Will be shipped soon.';
      case 'shipped': return 'Your order is on the way!';
      case 'delivered': return 'Order delivered. Enjoy your products!';
      case 'rejected': return 'Order rejected. Contact support.';
      default: return 'Payment under review. Admin will confirm within 24 hours.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade700,
        elevation: 0,
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _orders.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: Colors.green,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _orders.length,
                    itemBuilder: (context, i) => _OrderCard(
                      order: _orders[i],
                      statusColor: _statusColor(_orders[i]['status'] ?? 'pending'),
                      statusEmoji: _statusEmoji(_orders[i]['status'] ?? 'pending'),
                      statusMessage: _statusMessage(_orders[i]['status'] ?? 'pending'),
                    ).animate().fadeIn(delay: Duration(milliseconds: i * 80)),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    final user = FirebaseAuth.instance.currentUser;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📦', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 16),
        const Text('No orders yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(user == null ? 'Please sign in to view orders' : 'Start shopping to see your orders here', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Browse Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color statusColor;
  final String statusEmoji;
  final String statusMessage;
  const _OrderCard({required this.order, required this.statusColor, required this.statusEmoji, required this.statusMessage});

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List? ?? [];
    final total = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final status = order['status'] ?? 'pending';
    final createdAt = order['created_at'] != null ? DateTime.tryParse(order['created_at']) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.06), borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Order #${order['id']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  if (createdAt != null) Text('${createdAt.day}/${createdAt.month}/${createdAt.year}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text('$statusEmoji ${status.toUpperCase()}', style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Row(children: [
                      Text((item['product_name'] ?? '').contains('Pesticide') || (item['product_name'] ?? '').contains('spray') ? '🧪' : '🌿'),
                      const SizedBox(width: 6),
                      Expanded(child: Text('${item['product_name']} ×${item['quantity']}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                    ])),
                    Text('PKR ${((item['price'] as num? ?? 0) * (item['quantity'] as num? ?? 1)).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                )),
                const Divider(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('💳 ${order['payment_method'] ?? ''}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  Text('Total: PKR ${total.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.green.shade700, fontSize: 15)),
                ]),
              ],
            ),
          ),

          // Status message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.06), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18))),
            child: Row(children: [
              Text(statusEmoji),
              const SizedBox(width: 8),
              Expanded(child: Text(statusMessage, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500))),
            ]),
          ),

          if ((order['tracking_link'] ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: GestureDetector(
                child: Text('🚚 Track Package: ${order['tracking_link']}', style: TextStyle(color: Colors.blue.shade600, fontSize: 12, decoration: TextDecoration.underline)),
              ),
            ),
        ],
      ),
    );
  }
}
