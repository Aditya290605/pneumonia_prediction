import React, { useState } from 'react';
import LandingPage from './components/LandingPage';
import UploadScreen from './components/UploadScreen';
import ResultsScreen from './components/ResultsScreen';
import './animations.css';

export type PredictionResult = {
  prediction: string;
  probability: number;
  threshold_used: number;
  confidence: {
    PNEUMONIA: number;
    NORMAL: number;
  };
  diagnosed_image_url: string;
  report: string;
};

type Screen = 'landing' | 'upload' | 'results';

function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>('landing');
  const [results, setResults] = useState<PredictionResult | null>(null);
  const [uploadedImage, setUploadedImage] = useState<string | null>(null);

  const API_BASE = 'https://pneumonia-prediction-016u.onrender.com';

  const analyzeImage = async (file: File): Promise<PredictionResult> => {
    const formData = new FormData();
    formData.append('file', file);

    const response = await fetch(`${API_BASE}/predict`, {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      const message = `Analysis failed (${response.status}). Please try again.`;
      throw new Error(message);
    }

    const data: PredictionResult = await response.json();
    return data;
  };

  const handleGetStarted = () => {
    setCurrentScreen('upload');
  };

  const handleAnalysisComplete = (result: PredictionResult, imageUrl: string) => {
    setResults(result);
    setUploadedImage(imageUrl);
    setCurrentScreen('results');
  };

  const handleStartOver = () => {
    setCurrentScreen('landing');
    setResults(null);
    setUploadedImage(null);
  };

  const handleBackToUpload = () => {
    setCurrentScreen('upload');
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-[#0B1220] via-[#0A0F1A] to-black text-gray-200">
      <div className={`transition-all duration-700 ease-in-out ${
        currentScreen === 'landing' ? 'opacity-100 translate-x-0' :
        currentScreen === 'upload' ? 'opacity-100 translate-x-0' :
        'opacity-100 translate-x-0'
      }`}>
        {currentScreen === 'landing' && (
          <LandingPage onGetStarted={handleGetStarted} />
        )}
        {currentScreen === 'upload' && (
          <UploadScreen 
            onAnalysisComplete={handleAnalysisComplete}
            onBack={handleStartOver}
            onAnalyze={analyzeImage}
          />
        )}
        {currentScreen === 'results' && results && (
          <ResultsScreen 
            results={results}
            uploadedImage={uploadedImage}
            onStartOver={handleStartOver}
            onBackToUpload={handleBackToUpload}
          />
        )}
      </div>
    </div>
  );
}

export default App;