import React from 'react';
import { ArrowLeft, RefreshCw, Download, CheckCircle, AlertTriangle } from 'lucide-react';
import { PredictionResult } from '../App';
import ConfidenceChart from './ConfidenceChart';
import ReportDisplay from './ReportDisplay';

interface ResultsScreenProps {
  results: PredictionResult;
  uploadedImage: string | null;
  onStartOver: () => void;
  onBackToUpload: () => void;
}

const ResultsScreen: React.FC<ResultsScreenProps> = ({ 
  results, 
  uploadedImage, 
  onStartOver, 
  onBackToUpload 
}) => {
  const isNormal = results.prediction === 'NORMAL';
  const probabilityPercentage = (results.probability * 100).toFixed(2);

  return (
    <div className="min-h-screen py-12 px-6">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-8 animate-fade-in-up">
          <div className="flex items-center gap-4">
            <button
              onClick={onBackToUpload}
              className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-full transition-colors"
            >
              <ArrowLeft className="w-6 h-6" />
            </button>
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Analysis Results</h1>
              <p className="text-gray-600 mt-1">AI-powered chest X-ray diagnosis</p>
            </div>
          </div>
          
          <div className="flex gap-3">
            <button
              onClick={onStartOver}
              className="flex items-center gap-2 px-4 py-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <RefreshCw className="w-4 h-4" />
              Start Over
            </button>
            <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors">
              <Download className="w-4 h-4" />
              Download Report
            </button>
          </div>
        </div>

        {/* Main Results Grid */}
        <div className="grid lg:grid-cols-3 gap-8">
          {/* Left Column - Images and Primary Results */}
          <div className="lg:col-span-2 space-y-6">
            {/* Prediction Status */}
            <div className="medical-card rounded-2xl p-6 animate-slide-in-right">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold">Diagnosis</h2>
                <div className={`flex items-center gap-2 px-4 py-2 rounded-full font-semibold ${
                  isNormal 
                    ? 'bg-green-100 text-green-800' 
                    : 'bg-red-100 text-red-800'
                }`}>
                  {isNormal ? (
                    <CheckCircle className="w-5 h-5" />
                  ) : (
                    <AlertTriangle className="w-5 h-5" />
                  )}
                  {results.prediction}
                </div>
              </div>
              
              <div className="grid grid-cols-2 gap-6">
                <div className="text-center">
                  <div className="text-3xl font-bold text-gray-900 mb-2">
                    {probabilityPercentage}%
                  </div>
                  <div className="text-gray-600">Probability Score</div>
                </div>
                <div className="text-center">
                  <div className="text-3xl font-bold text-gray-900 mb-2">
                    {(results.threshold_used * 100).toFixed(1)}%
                  </div>
                  <div className="text-gray-600">Threshold Used</div>
                </div>
              </div>
            </div>

            {/* Images Comparison */}
            <div className="medical-card rounded-2xl p-6 animate-slide-in-right" style={{ animationDelay: '0.1s' }}>
              <h2 className="text-xl font-bold mb-6">Image Analysis</h2>
              <div className="grid md:grid-cols-2 gap-6">
                {/* Original Image */}
                <div>
                  <h3 className="font-semibold mb-3 text-gray-700">Original X-Ray</h3>
                  <div className="aspect-square bg-gray-100 rounded-xl overflow-hidden">
                    {uploadedImage ? (
                      <img
                        src={uploadedImage}
                        alt="Original chest X-ray"
                        className="w-full h-full object-contain"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-gray-400">
                        Original image not available
                      </div>
                    )}
                  </div>
                </div>

                {/* Diagnosed Image */}
                <div>
                  <h3 className="font-semibold mb-3 text-gray-700">AI Analysis</h3>
                  <div className="aspect-square bg-gray-100 rounded-xl overflow-hidden">
                    <img
                      src={`https://pneumonia-prediction-016u.onrender.com${results.diagnosed_image_url}`}
                      alt="AI diagnosed chest X-ray"
                      className="w-full h-full object-contain"
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.src = uploadedImage || '';
                      }}
                    />
                  </div>
                </div>
              </div>
            </div>

            {/* Detailed Report */}
            <div className="animate-slide-in-right" style={{ animationDelay: '0.2s' }}>
              <ReportDisplay report={results.report} />
            </div>
          </div>

          {/* Right Column - Confidence Chart and Stats */}
          <div className="space-y-6">
            {/* Confidence Chart */}
            <div className="medical-card rounded-2xl p-6 animate-slide-in-right" style={{ animationDelay: '0.3s' }}>
              <h2 className="text-xl font-bold mb-6">Confidence Analysis</h2>
              <ConfidenceChart 
                confidence={results.confidence}
                probability={results.probability}
                thresholdUsed={results.threshold_used}
              />
            </div>

            {/* Quick Stats */}
            <div className="medical-card rounded-2xl p-6 animate-slide-in-right" style={{ animationDelay: '0.4s' }}>
              <h2 className="text-xl font-bold mb-6">Analysis Summary</h2>
              <div className="space-y-4">
                <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                  <span className="font-medium">Model Prediction</span>
                  <span className={`font-bold ${isNormal ? 'text-green-600' : 'text-red-600'}`}>
                    {results.prediction}
                  </span>
                </div>
                <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                  <span className="font-medium">Confidence Level</span>
                  <span className="font-bold text-blue-600">
                    {Math.max(results.confidence.NORMAL, results.confidence.PNEUMONIA).toFixed(1)}%
                  </span>
                </div>
                <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                  <span className="font-medium">Analysis Time</span>
                  <span className="font-bold text-gray-600">&lt; 5 seconds</span>
                </div>
              </div>
            </div>

            {/* Disclaimer */}
            <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-xl text-sm text-yellow-800 animate-slide-in-right" style={{ animationDelay: '0.5s' }}>
              <div className="font-semibold mb-2">⚠️ Medical Disclaimer</div>
              <p>This AI analysis is for informational purposes only and should not replace professional medical diagnosis. Please consult with a qualified healthcare provider for proper medical evaluation.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ResultsScreen;