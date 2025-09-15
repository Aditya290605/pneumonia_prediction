import 'dart:ffi';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pneumonia_prediction/app/services/get_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  late AnimationController _chartController;
  late AnimationController _shimmerController;

  late Animation<double> _loadingAnimation;
  late Animation<double> _resultAnimation;
  late Animation<double> _chartAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _resultController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _chartController = AnimationController(
      duration: Duration(milliseconds: 1800),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOutCubic),
    );
    _resultAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
    );
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartController, curve: Curves.easeOutBack),
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _resultController.dispose();
    _chartController.dispose();
    _shimmerController.dispose();
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
      _chartController.forward();
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
            borderRadius: BorderRadius.circular(16),
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
        await Share.share(report, subject: 'Pneumonia Detection Report');
      } else {
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
            borderRadius: BorderRadius.circular(16),
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

  Widget _buildAdvancedConfidenceChart() {
    if (_result == null) return Container();

    final confidence =
        double.tryParse(_result!['confidence']['NORMAL'].toString()) ?? 0.0;
    final remainingConfidence = 100 - confidence;

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Container(
          height: 400,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade50,
                Colors.blue.shade100,
                Colors.blue.shade50,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.blue.shade200, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.analytics, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Confidence Analysis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: confidence * _chartAnimation.value,
                            title: confidence > 10
                                ? '${(confidence * _chartAnimation.value).toStringAsFixed(1)}%'
                                : '',
                            color: Colors.blue.shade700,
                            radius: 60 + (20 * _chartAnimation.value),
                            titleStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            badgeWidget: confidence > 80
                                ? Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.verified,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  )
                                : null,
                            badgePositionPercentageOffset: 1.3,
                          ),
                          PieChartSectionData(
                            value: remainingConfidence,
                            title: remainingConfidence > 10
                                ? '${remainingConfidence.toStringAsFixed(1)}%'
                                : '',
                            color: Colors.grey.shade300,
                            radius: 45,
                            titleStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        sectionsSpace: 4,
                        centerSpaceRadius: 50,
                        startDegreeOffset: -90,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(confidence * _chartAnimation.value).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        Text(
                          'Confidence',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem(
                    Colors.blue.shade700,
                    'Confident',
                    confidence,
                  ),
                  _buildLegendItem(
                    Colors.grey.shade400,
                    'Uncertain',
                    remainingConfidence,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label, double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 6),
        Text(
          '$label (${value.toStringAsFixed(1)}%)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedProbabilityChart() {
    if (_result == null) return Container();

    final probability =
        double.tryParse(_result!['probability'].toString()) ?? 0.0;
    final threshold =
        double.tryParse(_result!['threshold_used'].toString()) ?? 0.5;

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Container(
          height: 280,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade50,
                Colors.green.shade100,
                Colors.green.shade50,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.green.shade200, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.timeline, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Probability Score',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Expanded(
                child: BarChart(
                  BarChartData(
                    maxY: 1.0,
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: probability * _chartAnimation.value,
                            color: probability > threshold
                                ? Colors.red.shade600
                                : Colors.green.shade600,
                            width: 50,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            gradient: LinearGradient(
                              colors: probability > threshold
                                  ? [Colors.red.shade400, Colors.red.shade700]
                                  : [
                                      Colors.green.shade400,
                                      Colors.green.shade700,
                                    ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 1.0,
                              color: Colors.grey.shade200,
                            ),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: threshold,
                            color: Colors.orange.shade600,
                            width: 30,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
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
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Text(
                                value.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0:
                                return Text(
                                  'Score',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              case 1:
                                return Text(
                                  'Threshold',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              default:
                                return Text('');
                            }
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
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 0.25,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.green.shade200,
                          strokeWidth: 1,
                          dashArray: [5, 3],
                        );
                      },
                    ),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: threshold,
                          color: Colors.orange.shade600,
                          strokeWidth: 2,
                          dashArray: [8, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            labelResolver: (line) =>
                                'Threshold: ${threshold.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Center(
                child: Text(
                  'Score: ${(probability * _chartAnimation.value).toStringAsFixed(3)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskGaugeChart() {
    if (_result == null) return Container();

    final probability =
        double.tryParse(_result!['probability'].toString()) ?? 0.0;
    final riskLevel = probability > 0.7
        ? 'High'
        : probability > 0.4
        ? 'Medium'
        : 'Low';
    final riskColor = probability > 0.7
        ? Colors.red
        : probability > 0.4
        ? Colors.orange
        : Colors.green;

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Container(
          height: 250,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade50, Colors.purple.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purple.shade200, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.1),
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.speed, color: Colors.white, size: 18),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Risk Assessment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade900,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: probability * _chartAnimation.value,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          riskLevel,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                        Text(
                          'Risk',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(probability * _chartAnimation.value * 100).toStringAsFixed(1)}% Probability',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerCard(double height) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _shimmerAnimation.value * 2, -1.0),
              end: Alignment(1.0 + _shimmerAnimation.value * 2, 1.0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedLoadingAnimation() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 40),
      child: AnimatedBuilder(
        animation: _loadingAnimation,
        builder: (context, child) {
          return Column(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade200, Colors.blue.shade600],
                  ),
                ),
                child: LinearProgressIndicator(
                  value: _loadingAnimation.value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Analysis in Progress...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Processing X-Ray with deep learning models',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ... (keeping all other existing methods like _buildResultCard, _buildReport, etc.)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "AI Pneumonia Detection",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          if (_result != null)
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.download_rounded,
                  color: Colors.blue.shade600,
                ),
              ),
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
            // Enhanced Image Selection Card
            Container(
              padding: EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 30,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_selectedImageFile == null && _selectedImageBytes == null)
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade100, Colors.grey.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(
                                Icons.cloud_upload_outlined,
                                size: 48,
                                color: Colors.blue.shade400,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Upload X-Ray Image',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Select a chest X-ray for AI analysis',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _selectedImageFile != null
                          ? Image.file(
                              _selectedImageFile!,
                              height: 280,
                              fit: BoxFit.cover,
                            )
                          : Image.memory(
                              _selectedImageBytes!,
                              height: 280,
                              fit: BoxFit.cover,
                            ),
                    ),

                  SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: Icon(Icons.photo_library_rounded, size: 20),
                          label: Text(
                            'Select X-Ray',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
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
                              : Icon(Icons.auto_awesome, size: 20),
                          label: Text(
                            _loading ? 'Analyzing...' : 'AI Analyze',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Enhanced Loading Animation
            if (_loading) _buildEnhancedLoadingAnimation(),

            // Results Section with Enhanced Charts
            if (_result != null)
              FadeTransition(
                opacity: _resultAnimation,
                child: Column(
                  children: [
                    SizedBox(height: 30),

                    // Enhanced Main Result Card
                    Container(
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              _result!['prediction']
                                  .toString()
                                  .toLowerCase()
                                  .contains('pneumonia')
                              ? [
                                  Colors.red.shade400,
                                  Colors.red.shade600,
                                  Colors.red.shade700,
                                ]
                              : [
                                  Colors.green.shade400,
                                  Colors.green.shade600,
                                  Colors.green.shade700,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_result!['prediction']
                                            .toString()
                                            .toLowerCase()
                                            .contains('pneumonia')
                                        ? Colors.red
                                        : Colors.green)
                                    .withOpacity(0.4),
                            blurRadius: 25,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(
                              _result!['prediction']
                                      .toString()
                                      .toLowerCase()
                                      .contains('pneumonia')
                                  ? Icons.warning_rounded
                                  : Icons.verified_rounded,
                              size: 56,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'AI DIAGNOSIS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _result!['prediction'].toString(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Powered by Deep Learning AI',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Enhanced Charts Section
                    Column(
                      children: [
                        _buildAdvancedConfidenceChart(),
                        SizedBox(height: 20),
                        _buildAdvancedProbabilityChart(),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Risk Gauge Chart
                    _buildRiskGaugeChart(),

                    SizedBox(height: 20),

                    // Enhanced Metrics Cards
                    Column(
                      children: [
                        _buildEnhancedMetricCard(
                          'Probability',
                          _result!['probability'].toString(),
                          Icons.percent_rounded,
                          Colors.blue,
                          'Model confidence score',
                        ),
                        SizedBox(height: 12),
                        _buildEnhancedMetricCard(
                          'Threshold',
                          _result!['threshold_used'].toString(),
                          Icons.tune_rounded,
                          Colors.purple,
                          'Decision boundary',
                        ),
                        SizedBox(height: 12),
                        _buildEnhancedMetricCard(
                          'Confidence',
                          _result!['confidence'].toString(),
                          Icons.verified_rounded,
                          Colors.green,
                          'Analysis reliability',
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Enhanced Diagnosed Image Section
                    if (_result!['diagnosed_image_url'] != null)
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.indigo.shade400,
                                        Colors.indigo.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.medical_information,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI Analysis Visualization',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        'Heat map overlay showing analyzed regions',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                "https://pneumonia-prediction-016u.onrender.com${_result!['diagnosed_image_url']}",
                                width: double.infinity,
                                height: 280,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 280,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey.shade200,
                                          Colors.grey.shade100,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
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
                                          SizedBox(height: 12),
                                          Text(
                                            "Could not load analyzed image",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 280,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                            strokeWidth: 3,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Loading analysis...',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 24),

                    // Enhanced Detailed Report
                    if (_result!['report'] != null &&
                        _result!['report'] is String)
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.teal.shade400,
                                        Colors.teal.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.description_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Comprehensive Medical Report',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        'Detailed analysis and recommendations',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            _buildEnhancedReport(_result!['report']),
                          ],
                        ),
                      ),

                    SizedBox(height: 30),

                    // Enhanced Action Buttons
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
                              _chartController.reset();
                            },
                            icon: Icon(Icons.refresh_rounded, size: 20),
                            label: Text(
                              'New Analysis',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade700,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _downloadReport,
                            icon: Icon(Icons.download_rounded, size: 20),
                            label: Text(
                              'Download Report',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedMetricCard(
    String title,
    String value,
    IconData icon,
    MaterialColor color,
    String subtitle,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color.shade600, size: 28),
          ),
          SizedBox(height: 12),
          Text(
            "$value",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color.shade800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedResultCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedReport(String reportText) {
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
        _buildEnhancedResultCard(
          "Diagnosis",
          diagnosis.trim(),
          Icons.medical_services_rounded,
          Colors.blue.shade600,
        ),
        SizedBox(height: 16),
        _buildEnhancedResultCard(
          "Confidence Assessment",
          confidence.trim(),
          Icons.verified_rounded,
          Colors.purple.shade600,
        ),
        SizedBox(height: 16),
        _buildEnhancedResultCard(
          "Health Guidance",
          guidance.trim(),
          Icons.health_and_safety_rounded,
          Colors.green.shade600,
        ),
        SizedBox(height: 16),
        _buildEnhancedResultCard(
          "Next Steps",
          nextSteps.trim(),
          Icons.arrow_forward_rounded,
          Colors.orange.shade600,
        ),
      ],
    );
  }
}
