import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/backend_service.dart';

class PakistanMarketScreen extends StatefulWidget {
  const PakistanMarketScreen({super.key});

  @override
  State<PakistanMarketScreen> createState() => _PakistanMarketScreenState();
}

class _PakistanMarketScreenState extends State<PakistanMarketScreen> {
  List<Map<String, dynamic>> _rates = [];
  bool _loading = true;
  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rates = await BackendService.instance.getMarketRates();
    if (mounted) setState(() { _rates = rates; _loading = false; _lastUpdated = DateTime.now(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.teal.shade700, Colors.green.shade600]),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('📈 Live Market Rates', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Pakistan Agricultural Markets — PKR', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                      const SizedBox(height: 8),
                      Text('Updated: ${_lastUpdated.hour.toString().padLeft(2,'0')}:${_lastUpdated.minute.toString().padLeft(2,'0')}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.teal)))
          else if (_rates.isEmpty)
            SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('📊', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('No market data available', style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Refresh', style: TextStyle(color: Colors.white))),
            ])))
          else
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _RateCard(rate: _rates[i], index: i),
                  childCount: _rates.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        backgroundColor: Colors.teal.shade600,
        child: const Icon(Icons.refresh_rounded, color: Colors.white),
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  final Map<String, dynamic> rate;
  final int index;
  const _RateCard({required this.rate, required this.index});

  @override
  Widget build(BuildContext context) {
    final change = (rate['change_pct'] as num?)?.toDouble() ?? 0;
    final isUp = change > 0;
    final isDown = change < 0;
    final price = (rate['price'] as num).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isUp ? Colors.green.shade50 : isDown ? Colors.red.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isUp ? Icons.trending_up_rounded : isDown ? Icons.trending_down_rounded : Icons.trending_flat_rounded,
                  color: isUp ? Colors.green.shade600 : isDown ? Colors.red.shade600 : Colors.grey, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${isUp ? '+' : ''}${change.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isUp ? Colors.green.shade600 : isDown ? Colors.red.shade600 : Colors.grey),
                ),
              ]),
            ),
            const Spacer(),
            Text(rate['crop_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('PKR ${price.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.teal.shade700)),
            Text(rate['unit'] ?? 'per 40kg', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 60)).slideY(begin: 0.1);
  }
}
