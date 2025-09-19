class PredictionModel {
  final String prediction;
  final double probability;
  final double thresholdUsed;
  final Map<String, double> confidence;
  final String diagnosedImageUrl;
  final String report;

  PredictionModel({
    required this.prediction,
    required this.probability,
    required this.thresholdUsed,
    required this.confidence,
    required this.diagnosedImageUrl,
    required this.report,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      prediction: json['prediction'] ?? '',
      probability: (json['probability'] ?? 0.0).toDouble(),
      thresholdUsed: (json['threshold_used'] ?? 0.0).toDouble(),
      confidence: Map<String, double>.from(
        json['confidence']?.map((key, value) => MapEntry(key, value.toDouble())) ?? {},
      ),
      diagnosedImageUrl: json['diagnosed_image_url'] ?? '',
      report: json['report'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prediction': prediction,
      'probability': probability,
      'threshold_used': thresholdUsed,
      'confidence': confidence,
      'diagnosed_image_url': diagnosedImageUrl,
      'report': report,
    };
  }
}