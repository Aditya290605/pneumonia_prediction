import React from 'react';
import { Stethoscope, Brain, Shield, Zap } from 'lucide-react';

interface LandingPageProps {
  onGetStarted: () => void;
}

const LandingPage: React.FC<LandingPageProps> = ({ onGetStarted }) => {
  return (
    <div className="min-h-screen flex flex-col justify-center items-center relative overflow-hidden">
      {/* Animated Background Elements - Dark neon */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute -top-24 -left-24 w-72 h-72 rounded-full blur-3xl opacity-30" style={{ background: 'radial-gradient(circle at center, #22d3ee33, transparent 60%)' }} />
        <div className="absolute -bottom-24 -right-24 w-96 h-96 rounded-full blur-3xl opacity-25" style={{ background: 'radial-gradient(circle at center, #a78bfa33, transparent 60%)' }} />
        <div className="absolute top-1/3 left-1/4 w-40 h-40 rounded-full blur-2xl opacity-20" style={{ background: 'radial-gradient(circle at center, #60a5fa55, transparent 60%)' }} />
      </div>

      <div className="text-center z-10 max-w-5xl mx-auto px-6">
        {/* Main Title */}
        <div className="animate-fade-in-up">
          <div className="flex justify-center mb-6">
            <div className="p-4 glass-effect rounded-2xl shadow-xl">
              <Stethoscope className="w-12 h-12 text-cyan-300" />
            </div>
          </div>
          <h1 className="text-5xl md:text-6xl lg:text-7xl font-extrabold mb-6 gradient-text leading-tight tracking-tight">
            AI-Powered Pneumonia Detection
          </h1>
          <p className="text-xl md:text-2xl text-gray-300 mb-12 max-w-2xl mx-auto leading-relaxed">
            Advanced machine learning technology for rapid and accurate chest X-ray analysis
          </p>
        </div>

        {/* Feature Cards */}
        <div className="grid md:grid-cols-3 gap-6 mb-12 animate-slide-in-right">
          <div className="medical-card rounded-2xl p-6">
            <Brain className="w-8 h-8 text-cyan-300 mb-4 mx-auto" />
            <h3 className="text-lg font-semibold mb-2 text-white">AI-Powered Analysis</h3>
            <p className="text-gray-300/80 text-sm">Advanced deep learning algorithms trained on thousands of chest X-rays</p>
          </div>
          
          <div className="medical-card rounded-2xl p-6" style={{ animationDelay: '0.2s' }}>
            <Zap className="w-8 h-8 text-indigo-300 mb-4 mx-auto" />
            <h3 className="text-lg font-semibold mb-2 text-white">Instant Results</h3>
            <p className="text-gray-300/80 text-sm">Get comprehensive diagnostic reports in seconds, not hours</p>
          </div>
          
          <div className="medical-card rounded-2xl p-6" style={{ animationDelay: '0.4s' }}>
            <Shield className="w-8 h-8 text-sky-300 mb-4 mx-auto" />
            <h3 className="text-lg font-semibold mb-2 text-white">Clinical Accuracy</h3>
            <p className="text-gray-300/80 text-sm">Professional-grade analysis with detailed confidence metrics</p>
          </div>
        </div>

        {/* CTA Button */}
        <div className="animate-fade-in-up" style={{ animationDelay: '0.6s' }}>
          <button
            onClick={onGetStarted}
            className="glass-effect text-white font-semibold py-4 px-8 rounded-full text-lg shadow-xl hover:shadow-2xl transform hover:scale-105 transition-all duration-300 flex items-center gap-3 mx-auto border border-white/10"
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
            <div className="text-2xl font-bold text-cyan-300">98%</div>
            <div className="text-sm text-gray-400">Accuracy</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-indigo-300">&lt;5s</div>
            <div className="text-sm text-gray-400">Analysis Time</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-sky-300">24/7</div>
            <div className="text-sm text-gray-400">Available</div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LandingPage;