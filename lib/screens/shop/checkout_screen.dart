import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import '../../providers/cart_provider.dart';
import '../../services/backend_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cart = CartProvider.instance;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  String _paymentMethod = 'JazzCash';
  Uint8List? _screenshotBytes;
  String? _screenshotName;
  bool _placing = false;

  final _paymentDetails = {
    'JazzCash': {'number': '0300-1234567', 'icon': '📱', 'color': 0xFFc0392b, 'hint': 'Open JazzCash → Send Money → Enter number → Screenshot'},
    'Easypaisa': {'number': '0300-7654321', 'icon': '📱', 'color': 0xFF27ae60, 'hint': 'Open Easypaisa → Send Money → Enter number → Screenshot'},
    'BankTransfer': {'number': 'HBL — 0123456789012', 'icon': '🏦', 'color': 0xFF2980b9, 'hint': 'Transfer to account above and screenshot the transaction'},
  };

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameCtrl.text = user.displayName ?? '';
      _emailCtrl.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _addressCtrl.dispose(); _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() { _screenshotBytes = bytes; _screenshotName = file.name; });
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_screenshotBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Please upload payment screenshot'), backgroundColor: Colors.orange.shade600, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }
    setState(() => _placing = true);
    final result = await BackendService.instance.placeOrder(
      farmerName: _nameCtrl.text,
      farmerEmail: _emailCtrl.text,
      farmerPhone: _phoneCtrl.text,
      billingAddress: _addressCtrl.text,
      billingCity: _cityCtrl.text,
      paymentMethod: _paymentMethod,
      items: _cart.toOrderItems(),
      totalAmount: _cart.total,
      paymentScreenshot: _screenshotBytes,
      screenshotFilename: _screenshotName,
    );
    setState(() => _placing = false);

    if (!mounted) return;
    if (result['success'] == true) {
      _cart.clear();
      _showSuccessDialog(result['order_id']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error'] ?? 'Order failed'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }

  void _showSuccessDialog(dynamic orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('✅', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          const Text('Order Placed!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Order #$orderId submitted.\nAdmin will review your payment within 24 hours.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, height: 1.4)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _cart.total;
    final payInfo = _paymentDetails[_paymentMethod]!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade700,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Your Details
              _Block(title: '👤 Your Details', children: [
                _Input(ctrl: _nameCtrl, label: 'Full Name', hint: 'Muhammad Ahmed', validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                _Input(ctrl: _emailCtrl, label: 'Email', hint: 'ahmed@gmail.com', keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                _Input(ctrl: _phoneCtrl, label: 'Phone Number *', hint: '+92 300 0000000', keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
              ]).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 14),

              // Shipping
              _Block(title: '📍 Delivery Address', children: [
                _Input(ctrl: _addressCtrl, label: 'Street / Village', hint: 'House #, Street, Village/Town', validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                _Input(ctrl: _cityCtrl, label: 'City', hint: 'Lahore, Faisalabad, Multan...', validator: (v) => v!.isEmpty ? 'Required' : null),
              ]).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 14),

              // Payment method
              _Block(title: '💳 Payment Method', children: [
                ..._paymentDetails.entries.map((entry) {
                  final selected = _paymentMethod == entry.key;
                  return GestureDetector(
                    onTap: () => setState(() => _paymentMethod = entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected ? Color(entry.value['color'] as int).withOpacity(0.06) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? Color(entry.value['color'] as int) : Colors.grey.shade200, width: selected ? 2 : 1),
                      ),
                      child: Row(children: [
                        Text(entry.value['icon'] as String, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(entry.value['number'] as String, style: TextStyle(color: Color(entry.value['color'] as int), fontWeight: FontWeight.w600, fontSize: 13)),
                        ])),
                        if (selected) Icon(Icons.check_circle_rounded, color: Color(entry.value['color'] as int)),
                      ]),
                    ),
                  );
                }),
                // Payment instructions
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('💡 How to Pay (${_paymentMethod}):', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(payInfo['hint'] as String, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                    const SizedBox(height: 8),
                    Text('Amount: PKR ${total.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.green.shade700, fontSize: 15)),
                  ]),
                ),
              ]).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 14),

              // Screenshot upload
              _Block(title: '📸 Payment Screenshot *', children: [
                Text('After sending payment, upload a screenshot as proof of payment', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickScreenshot,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _screenshotBytes != null ? null : 100,
                    decoration: BoxDecoration(
                      color: _screenshotBytes != null ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _screenshotBytes != null ? Colors.green.shade300 : Colors.grey.shade300, style: BorderStyle.solid, width: 1.5),
                    ),
                    child: _screenshotBytes != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_screenshotBytes!, fit: BoxFit.cover))
                        : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.upload_rounded, color: Colors.grey, size: 36),
                            SizedBox(height: 6),
                            Text('Tap to upload screenshot', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ])),
                  ),
                ),
                if (_screenshotBytes != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(onTap: _pickScreenshot, child: Text('Change screenshot', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13))),
                ],
              ]).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 14),

              // Order summary
              _Block(title: '🧾 Order Summary', children: [
                ..._cart.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text('${item.name} ×${item.quantity}', style: const TextStyle(fontSize: 13))),
                    Text('PKR ${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                )),
                const Divider(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Delivery', style: TextStyle(fontSize: 14)),
                  Text('Free 🚚', style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('PKR ${total.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.green.shade700)),
                ]),
              ]).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _placing ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: Colors.green.shade200,
                  ),
                  child: _placing
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('🛒 Place Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Block({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))]),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 14),
          ...children,
        ]),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const _Input({required this.ctrl, required this.label, required this.hint, this.keyboardType, this.validator});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
      const SizedBox(height: 5),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.green.shade400, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    ]);
  }
}
