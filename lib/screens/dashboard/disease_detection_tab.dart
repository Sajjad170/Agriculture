import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/disease_history_card.dart';
import '../../services/detection_service.dart';
import '../../services/chat_service.dart';

class DiseaseDetectionTab extends StatefulWidget {
  const DiseaseDetectionTab({super.key});

  @override
  State<DiseaseDetectionTab> createState() => _DiseaseDetectionTabState();
}

class _DiseaseDetectionTabState extends State<DiseaseDetectionTab> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  DiseaseAnalysisResult? _analysisResult;
  final List<DiseaseHistory> _detectionHistory = [];
  final VisionApiService _visionService = VisionApiService();
  final GeminiApiService _geminiService = GeminiApiService();

  @override
  void initState() {
    super.initState();
    _loadDetectionHistory();
  }

  void _loadDetectionHistory() {
    // Load initial mock history
    _detectionHistory.addAll([
      DiseaseHistory(
        cropName: 'Tomato',
        diseaseName: 'Early Blight',
        date: '2 days ago',
        severity: 'Moderate',
        imagePath: 'assets/detection/leaf.png',
        confidence: 85,
        treatment: 'Apply copper-based fungicides',
      ),
      DiseaseHistory(
        cropName: 'Potato',
        diseaseName: 'Late Blight',
        date: '1 week ago',
        severity: 'Severe',
        imagePath: 'assets/detection/leaf.png',
        confidence: 92,
        treatment: 'Remove infected plants immediately',
      ),
      DiseaseHistory(
        cropName: 'Corn',
        diseaseName: 'Northern Leaf Blight',
        date: '2 weeks ago',
        severity: 'Mild',
        imagePath: 'assets/detection/leaf.png',
        confidence: 78,
        treatment: 'Use resistant varieties',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Detection'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          if (_detectionHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: _showFullHistory,
              tooltip: 'View Full History',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Analysis Results Section
              if (_analysisResult != null) _buildAnalysisResults(),

              // Camera Section
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: _selectedImage != null
                    ? _buildImagePreview()
                    : _buildCameraPlaceholder(),
              ),

              const SizedBox(height: 24),

              // Analysis Button (only show when image is selected)
              if (_selectedImage != null && !_isAnalyzing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _analyzeImage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text(
                      'Analyze for Diseases',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              if (_isAnalyzing)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Analyzing image for diseases...',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Tips Section
              if (_analysisResult == null) _buildTipsSection(),

              const SizedBox(height: 24),

              // Recent Detection History
              if (_detectionHistory.isNotEmpty) _buildDetectionHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _getSeverityColor(_analysisResult!.severity).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getSeverityColor(_analysisResult!.severity).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: _getSeverityColor(_analysisResult!.severity),
              ),
              const SizedBox(width: 8),
              Text(
                'Analysis Results',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getSeverityColor(_analysisResult!.severity),
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _analysisResult!.diseaseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Crop: ${_analysisResult!.cropName}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getSeverityColor(_analysisResult!.severity).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _analysisResult!.severity,
                  style: TextStyle(
                    color: _getSeverityColor(_analysisResult!.severity),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Confidence: ${_analysisResult!.confidence}%',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _analysisResult!.description,
            style: const TextStyle(
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (_analysisResult!.treatment.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended Treatment:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getSeverityColor(_analysisResult!.severity),
                  ),
                ),
                const SizedBox(height: 4),
                Text(_analysisResult!.treatment),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearAnalysis,
                  child: const Text('New Analysis'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveToHistory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getSeverityColor(_analysisResult!.severity),
                  ),
                  child: const Text(
                    'Save to History',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Tips for Better Detection',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('Take clear, well-lit photos of the affected area'),
          _buildTipItem('Include both healthy and diseased parts for comparison'),
          _buildTipItem('Avoid shadows and glare on the plant surface'),
          _buildTipItem('Take multiple photos from different angles if needed'),
        ],
      ),
    );
  }

  Widget _buildDetectionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Detection History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _showFullHistory,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._detectionHistory.take(3).map((history) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DiseaseHistoryCard(
            cropName: history.cropName,
            diseaseName: history.diseaseName,
            date: history.date,
            severity: history.severity,
            imagePath: history.imagePath,
            onTap: () => _showHistoryDetails(history),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildCameraPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Take a photo of your crop',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Our AI will analyze and detect any diseases',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Upload'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            _selectedImage!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _showImageSourceDialog,
              icon: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _removeImage,
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Image handling methods
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null; // Clear previous results
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null; // Clear previous results
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Image'),
        content: const Text('Choose image source'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _takePhoto();
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _analysisResult = null;
    });
  }

  // Analysis methods
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Use your Vision API service
      final analysisData = await _visionService.detectCropCondition(_selectedImage!);

      // Get detailed analysis from Gemini
      final response = await _geminiService.getResponse(
          "Analyze this plant/crop for diseases and provide recommendations. Include: disease name, severity (mild/moderate/severe), confidence percentage, description, and treatment recommendations.",
          contextData: analysisData
      );

      // Parse the response and create analysis result
      final result = _parseAnalysisResponse(response);

      setState(() {
        _analysisResult = result;
      });

    } catch (e) {
      _showErrorSnackBar('Analysis failed: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  DiseaseAnalysisResult _parseAnalysisResponse(String response) {
    // Simple parsing - you might want to make this more robust
    // This is a mock implementation - adapt based on your actual API response
    return DiseaseAnalysisResult(
      diseaseName: 'Early Blight',
      cropName: 'Tomato',
      severity: 'Moderate',
      confidence: 85,
      description: 'Early blight is a common fungal disease that affects tomato plants. It appears as dark spots with concentric rings on lower leaves.',
      treatment: 'Apply copper-based fungicides every 7-10 days. Remove infected leaves. Improve air circulation.',
      imagePath: _selectedImage!.path,
    );
  }

  void _saveToHistory() {
    if (_analysisResult == null) return;

    final newHistory = DiseaseHistory(
      cropName: _analysisResult!.cropName,
      diseaseName: _analysisResult!.diseaseName,
      date: 'Just now',
      severity: _analysisResult!.severity,
      imagePath: _analysisResult!.imagePath,
      confidence: _analysisResult!.confidence,
      treatment: _analysisResult!.treatment,
    );

    setState(() {
      _detectionHistory.insert(0, newHistory); // Add to beginning
    });

    _showSuccessSnackBar('Saved to detection history');
  }

  void _clearAnalysis() {
    setState(() {
      _analysisResult = null;
      _selectedImage = null;
    });
  }

  void _showHistoryDetails(DiseaseHistory history) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(history.diseaseName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Crop: ${history.cropName}'),
              Text('Severity: ${history.severity}'),
              Text('Confidence: ${history.confidence}%'),
              if (history.treatment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Treatment: ${history.treatment}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFullHistory() {
    // Navigate to full history page or show dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Full Detection History'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _detectionHistory.length,
            itemBuilder: (context, index) {
              final history = _detectionHistory[index];
              return ListTile(
                leading: Image.asset(history.imagePath, width: 40, height: 40),
                title: Text(history.diseaseName),
                subtitle: Text('${history.cropName} • ${history.date}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(history.severity).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    history.severity,
                    style: TextStyle(
                      color: _getSeverityColor(history.severity),
                      fontSize: 12,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showHistoryDetails(history);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Models for analysis results and history
class DiseaseAnalysisResult {
  final String diseaseName;
  final String cropName;
  final String severity;
  final int confidence;
  final String description;
  final String treatment;
  final String imagePath;

  DiseaseAnalysisResult({
    required this.diseaseName,
    required this.cropName,
    required this.severity,
    required this.confidence,
    required this.description,
    required this.treatment,
    required this.imagePath,
  });
}

class DiseaseHistory {
  final String cropName;
  final String diseaseName;
  final String date;
  final String severity;
  final String imagePath;
  final int confidence;
  final String treatment;

  DiseaseHistory({
    required this.cropName,
    required this.diseaseName,
    required this.date,
    required this.severity,
    required this.imagePath,
    required this.confidence,
    required this.treatment,
  });
}