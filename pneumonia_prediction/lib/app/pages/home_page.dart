import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pneumonia_prediction/app/services/get_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:math' as math;

class PredictScreen extends StatefulWidget {
  @override
  _PredictScreenState createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen>
    with TickerProviderStateMixin {
  io.File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  Map<String, dynamic>? _result;
  bool _loading = false;

  late AnimationController _loadingController;
  late AnimationController _resultController;
  late Animation<double> _loadingAnimation;
  late Animation<double> _resultAnimation;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _resultController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
    _resultAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      HapticFeedback.lightImpact();
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageFile = null;
          _result = null;
        });
      } else {
        setState(() {
          _selectedImageFile = io.File(pickedFile.path);
          _selectedImageBytes = null;
          _result = null;
        });
      }
    }
  }

  Future<void> _sendToApi() async {
    if (_selectedImageFile == null && _selectedImageBytes == null) return;

    setState(() => _loading = true);
    _loadingController.forward();
    HapticFeedback.mediumImpact();

    try {
      final res = await ApiService.predict(
        file: _selectedImageFile,
        bytes: _selectedImageBytes,
      );
      setState(() => _result = res);
      _resultController.forward();
      HapticFeedback.heavyImpact();
    } catch (e) {
      print(e);
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text("Error: $e")),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() => _loading = false);
      _loadingController.reverse();
    }
  }

  Future<void> _downloadReport() async {
    if (_result == null) return;

    try {
      // Create a simple text report
      String report =
          """
PNEUMONIA DETECTION REPORT
==========================

Prediction: ${_result!['prediction']}
Probability: ${_result!['probability']}
Confidence: ${_result!['confidence']}
Threshold Used: ${_result!['threshold_used']}

${_result!['report'] ?? 'No detailed report available'}

Generated on: ${DateTime.now().toString()}
      """;

      if (kIsWeb) {
        // For web, we can use the share functionality
        await Share.share(report, subject: 'Pneumonia Detection Report');
      } else {
        // For mobile, save to documents
        final directory = await getApplicationDocumentsDirectory();
        final file = io.File(
          '${directory.path}/pneumonia_report_${DateTime.now().millisecondsSinceEpoch}.txt',
        );
        await file.writeAsString(report);

        await Share.shareXFiles([
          XFile(file.path),
        ], subject: 'Pneumonia Detection Report');
      }

      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.download_done, color: Colors.white),
              SizedBox(width: 8),
              Text("Report downloaded successfully!"),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to download report: $e"),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Widget _buildConfidenceChart() {
    if (_result == null) return Container();

    final confidence =
        double.tryParse(_result!['confidence'].toString()) ?? 0.0;
    final probability =
        double.tryParse(_result!['probability'].toString()) ?? 0.0;

    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue.shade700),
              SizedBox(width: 8),
              Text(
                'Analysis Metrics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: confidence,
                    title: '${confidence.toStringAsFixed(1)}%',
                    color: Colors.blue.shade600,
                    radius: 50,
                    titleStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 100 - confidence,
                    title: '${(100 - confidence).toStringAsFixed(1)}%',
                    color: Colors.grey.shade300,
                    radius: 40,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          Text(
            'Confidence Level',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityBar() {
    if (_result == null) return Container();

    final probability =
        double.tryParse(_result!['probability'].toString()) ?? 0.0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.green.shade700),
              SizedBox(width: 8),
              Text(
                'Probability Score',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            height: 80,
            child: BarChart(
              BarChartData(
                maxY: 1.0,
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: probability,
                        color: probability > 0.5
                            ? Colors.red.shade600
                            : Colors.green.shade600,
                        width: 40,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'Score',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true, drawVerticalLine: false),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Score: ${probability.toStringAsFixed(3)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color is MaterialColor
                      ? color.shade800
                      : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildReport(String reportText) {
    final lines = reportText.split("\n");
    String diagnosis = "";
    String confidence = "";
    String guidance = "";
    String nextSteps = "";

    String current = "";
    for (var line in lines) {
      line = line.trim();
      if (line.startsWith("**1. Diagnosis")) {
        current = "diagnosis";
      } else if (line.startsWith("**2. Confidence")) {
        current = "confidence";
      } else if (line.startsWith("**3. General Health")) {
        current = "guidance";
      } else if (line.startsWith("**4. Recommended")) {
        current = "next";
      } else {
        if (current == "diagnosis") diagnosis += line + "\n";
        if (current == "confidence") confidence += line + "\n";
        if (current == "guidance") guidance += line + "\n";
        if (current == "next") nextSteps += line + "\n";
      }
    }

    return Column(
      children: [
        _buildResultCard(
          "Diagnosis",
          diagnosis.trim(),
          Icons.medical_services,
          Colors.blue,
        ),
        SizedBox(height: 12),
        _buildResultCard(
          "Confidence Assessment",
          confidence.trim(),
          Icons.verified,
          Colors.purple,
        ),
        SizedBox(height: 12),
        _buildResultCard(
          "Health Guidance",
          guidance.trim(),
          Icons.health_and_safety,
          Colors.green,
        ),
        SizedBox(height: 12),
        _buildResultCard(
          "Next Steps",
          nextSteps.trim(),
          Icons.arrow_forward,
          Colors.orange,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Pneumonia Detection",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          if (_result != null)
            IconButton(
              icon: Icon(Icons.download_rounded),
              onPressed: _downloadReport,
              tooltip: 'Download Report',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Selection Card
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_selectedImageFile == null && _selectedImageBytes == null)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No X-Ray Image Selected',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _selectedImageFile != null
                          ? Image.file(
                              _selectedImageFile!,
                              height: 250,
                              fit: BoxFit.cover,
                            )
                          : Image.memory(
                              _selectedImageBytes!,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                    ),

                  SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: Icon(Icons.photo_library_rounded),
                          label: Text('Select X-Ray'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              (_selectedImageFile != null ||
                                      _selectedImageBytes != null) &&
                                  !_loading
                              ? _sendToApi
                              : null,
                          icon: _loading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(Icons.analytics_rounded),
                          label: Text(_loading ? 'Analyzing...' : 'Analyze'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Loading Animation
            if (_loading)
              Container(
                margin: EdgeInsets.symmetric(vertical: 30),
                child: AnimatedBuilder(
                  animation: _loadingAnimation,
                  builder: (context, child) {
                    return Column(
                      children: [
                        LinearProgressIndicator(
                          value: _loadingAnimation.value,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.shade600,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Analyzing X-Ray Image...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            // Results Section
            if (_result != null)
              FadeTransition(
                opacity: _resultAnimation,
                child: Column(
                  children: [
                    SizedBox(height: 30),

                    // Main Result Card
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              _result!['prediction']
                                  .toString()
                                  .toLowerCase()
                                  .contains('pneumonia')
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : [Colors.green.shade400, Colors.green.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_result!['prediction']
                                            .toString()
                                            .toLowerCase()
                                            .contains('pneumonia')
                                        ? Colors.red
                                        : Colors.green)
                                    .withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _result!['prediction']
                                    .toString()
                                    .toLowerCase()
                                    .contains('pneumonia')
                                ? Icons.warning_rounded
                                : Icons.check_circle_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'PREDICTION RESULT',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _result!['prediction'].toString(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Charts Row
                    Row(
                      children: [
                        Expanded(child: _buildConfidenceChart()),
                        SizedBox(width: 16),
                        Expanded(child: _buildProbabilityBar()),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Metrics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Probability',
                            _result!['probability'].toString(),
                            Icons.percent,
                            Colors.blue,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Threshold',
                            _result!['threshold_used'].toString(),
                            Icons.tune,
                            Colors.purple,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Confidence',
                            _result!['confidence'].toString(),
                            Icons.verified,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Diagnosed Image
                    if (_result!['diagnosed_image_url'] != null)
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.medical_information,
                                  color: Colors.blue.shade700,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'AI Analysis Visualization',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                "http://127.0.0.1:8000${_result!['diagnosed_image_url']}",
                                width: double.infinity,
                                height: 250,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 250,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 48,
                                            color: Colors.grey.shade400,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            "Could not load analyzed image",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 250,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 20),

                    // Detailed Report
                    if (_result!['report'] != null &&
                        _result!['report'] is String)
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: Colors.indigo.shade700,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Detailed Medical Report',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            _buildReport(_result!['report']),
                          ],
                        ),
                      ),

                    SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedImageFile = null;
                                _selectedImageBytes = null;
                                _result = null;
                              });
                              _resultController.reset();
                            },
                            icon: Icon(Icons.refresh_rounded),
                            label: Text('New Analysis'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _downloadReport,
                            icon: Icon(Icons.download_rounded),
                            label: Text('Download Report'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    MaterialColor color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color.shade600, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.shade800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
