import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendService {
  static BackendService? _instance;
  static BackendService get instance => _instance ??= BackendService._();
  BackendService._();

  // Injected at build time via --dart-define=BASE_URL=https://...
  // Falls back to Replit dev domain if not provided
  static const String _injectedUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://62717973-4b7a-4a00-8530-aacf8e2b64b4-00-1jmy84mplsnow.sisko.replit.dev',
  );

  static String get baseUrl {
    if (kIsWeb) {
      // Web: same origin through serve.dart proxy (port 5000 → 3001)
      final uri = Uri.base;
      final host = uri.host;
      final scheme = uri.scheme;
      return '$scheme://$host';
    }
    // Mobile: use Replit public domain (serve.dart proxies /api/* → port 3001)
    return _injectedUrl;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<List<Map<String, dynamic>>> getProducts({String? type, String? search}) async {
    try {
      final params = <String, String>{};
      if (type != null && type != 'all') params['type'] = type;
      if (search != null && search.isNotEmpty) params['search'] = search;
      final uri = Uri.parse('$baseUrl/api/products').replace(queryParameters: params.isNotEmpty ? params : null);
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
      debugPrint('getProducts status: ${res.statusCode}');
    } catch (e) {
      debugPrint('getProducts error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getMarketRates() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/market'), headers: _headers).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      debugPrint('getMarketRates status: ${res.statusCode}');
    } catch (e) {
      debugPrint('getMarketRates error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getAIRecommendation(String crop, String problem) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/ai/recommend'),
        headers: _headers,
        body: jsonEncode({'crop': crop, 'problem': problem}),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(res.body));
      debugPrint('getAIRecommendation status: ${res.statusCode}');
    } catch (e) {
      debugPrint('getAIRecommendation error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> placeOrder({
    required String farmerName,
    required String farmerEmail,
    required String farmerPhone,
    required String billingAddress,
    required String billingCity,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    Uint8List? paymentScreenshot,
    String? screenshotFilename,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/orders'));
      request.fields['farmer_name'] = farmerName;
      request.fields['farmer_email'] = farmerEmail;
      request.fields['farmer_phone'] = farmerPhone;
      request.fields['billing_name'] = farmerName;
      request.fields['billing_address'] = billingAddress;
      request.fields['billing_city'] = billingCity;
      request.fields['shipping_address'] = billingAddress;
      request.fields['shipping_city'] = billingCity;
      request.fields['payment_method'] = paymentMethod;
      request.fields['items'] = jsonEncode(items);
      request.fields['total_amount'] = totalAmount.toString();
      if (paymentScreenshot != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'payment_screenshot',
          paymentScreenshot,
          filename: screenshotFilename ?? 'payment.jpg',
        ));
      }
      final streamedRes = await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamedRes);
      return Map<String, dynamic>.from(jsonDecode(res.body));
    } catch (e) {
      debugPrint('placeOrder error: $e');
      return {'error': 'Connection failed. Please check your internet connection.'};
    }
  }

  Future<List<Map<String, dynamic>>> getOrdersByEmail(String email) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/orders/by-email/${Uri.encodeComponent(email)}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      debugPrint('getOrdersByEmail status: ${res.statusCode}');
    } catch (e) {
      debugPrint('getOrdersByEmail error: $e');
    }
    return [];
  }
}
