class CropPriceData {
  final String cropName;       // Name of the crop
  final double currentPrice;   // Current market price
  final double changePercent;  // Price change in percentage

  CropPriceData({
    required this.cropName,
    required this.currentPrice,
    required this.changePercent,
  });

  factory CropPriceData.fromJson(Map<String, dynamic> json) {
    return CropPriceData(
      cropName: json['cropName'] ?? '',
      currentPrice: (json['currentPrice'] ?? 0).toDouble(),
      changePercent: (json['changePercent'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cropName': cropName,
      'currentPrice': currentPrice,
      'changePercent': changePercent,
    };
  }
}
