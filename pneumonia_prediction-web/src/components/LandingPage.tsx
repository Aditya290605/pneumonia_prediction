import React from 'react';
import { Stethoscope, Brain, Shield, Zap } from 'lucide-react';

interface LandingPageProps {
  onGetStarted: () => void;
}

const LandingPage: React.FC<LandingPageProps> = ({ onGetStarted }) => {
  return (
    <div className="min-h-screen flex flex-col justify-center items-center relative overflow-hidden">
      {/* Animated Background Elements */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-10 left-10 w-20 h-20 bg-blue-200 rounded-full opacity-60 animate-pulse-subtle"></div>
        <div className="absolute top-40 right-20 w-16 h-16 bg-indigo-200 rounded-full opacity-40 animate-pulse-subtle" style={{ animationDelay: '1s' }}></div>
        <div className="absolute bottom-20 left-1/4 w-12 h-12 bg-cyan-200 rounded-full opacity-50 animate-pulse-subtle" style={{ animationDelay: '2s' }}></div>
        <div className="absolute bottom-40 right-1/3 w-8 h-8 bg-blue-300 rounded-full opacity-60 animate-pulse-subtle" style={{ animationDelay: '0.5s' }}></div>
      </div>

      <div className="text-center z-10 max-w-4xl mx-auto px-6">
        {/* Main Title */}
        <div className="animate-fade-in-up">
          <div className="flex justify-center mb-6">
            <div className="p-4 bg-blue-100 rounded-full">
              <Stethoscope className="w-12 h-12 text-blue-600" />
            </div>
          </div>
          <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold mb-6 gradient-text leading-tight">
            AI-Powered Pneumonia Detection
          </h1>
          <p className="text-xl md:text-2xl text-gray-600 mb-12 max-w-2xl mx-auto leading-relaxed">
            Advanced machine learning technology for rapid and accurate chest X-ray analysis
          </p>
        </div>

        {/* Feature Cards */}
        <div className="grid md:grid-cols-3 gap-6 mb-12 animate-slide-in-right">
          <div className="medical-card rounded-2xl p-6">
            <Brain className="w-8 h-8 text-blue-600 mb-4 mx-auto" />
            <h3 className="text-lg font-semibold mb-2">AI-Powered Analysis</h3>
            <p className="text-gray-600 text-sm">Advanced deep learning algorithms trained on thousands of chest X-rays</p>
          </div>
          
          <div className="medical-card rounded-2xl p-6" style={{ animationDelay: '0.2s' }}>
            <Zap className="w-8 h-8 text-blue-600 mb-4 mx-auto" />
            <h3 className="text-lg font-semibold mb-2">Instant Results</h3>
            <p className="text-gray-600 text-sm">Get comprehensive diagnostic reports in seconds, not hours</p>
          </div>
          
          <div className="medical-card rounded-2xl p-6" style={{ animationDelay: '0.4s' }}>
            <Shield className="w-8 h-8 text-blue-600 mb-4 mx-auto" />
            <h3 className="text-lg font-semibold mb-2">Clinical Accuracy</h3>
            <p className="text-gray-600 text-sm">Professional-grade analysis with detailed confidence metrics</p>
          </div>
        </div>

        {/* CTA Button */}
        <div className="animate-fade-in-up" style={{ animationDelay: '0.6s' }}>
          <button
            onClick={onGetStarted}
            className="bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-semibold py-4 px-8 rounded-full text-lg shadow-lg hover:shadow-xl transform hover:scale-105 transition-all duration-300 flex items-center gap-3 mx-auto"
          >
            Start Analysis
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
            </svg>
          </button>
        </div>

        {/* Statistics */}
        <div className="mt-16 grid grid-cols-3 gap-8 max-w-md mx-auto animate-fade-in-up" style={{ animationDelay: '0.8s' }}>
          <div className="text-center">
            <div className="text-2xl font-bold text-blue-600">98%</div>
            <div className="text-sm text-gray-600">Accuracy</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-blue-600">&lt;5s</div>
            <div className="text-sm text-gray-600">Analysis Time</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-blue-600">24/7</div>
            <div className="text-sm text-gray-600">Available</div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LandingPage;