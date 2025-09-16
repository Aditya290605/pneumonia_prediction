import React, { useState, useRef } from 'react';
import { Upload, ArrowLeft, FileImage, AlertCircle, Loader } from 'lucide-react';
import { PredictionResult } from '../App';

interface UploadScreenProps {
  onAnalysisComplete: (result: PredictionResult, imageUrl: string) => void;
  onBack: () => void;
  onAnalyze: (file: File) => Promise<PredictionResult>;
}

const UploadScreen: React.FC<UploadScreenProps> = ({ onAnalysisComplete, onBack, onAnalyze }) => {
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isDragOver, setIsDragOver] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = (file: File) => {
    if (file && file.type.startsWith('image/')) {
      setSelectedFile(file);
      const url = URL.createObjectURL(file);
      setPreviewUrl(url);
      setError(null);
    } else {
      setError('Please select a valid image file');
    }
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(true);
  };

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
    const files = e.dataTransfer.files;
    if (files.length > 0) {
      handleFileSelect(files[0]);
    }
  };

  const handleFileInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (files && files.length > 0) {
      handleFileSelect(files[0]);
    }
  };

  const handleAnalyze = async () => {
    if (!selectedFile) return;

    setIsAnalyzing(true);
    setError(null);

    try {
      const result: PredictionResult = await onAnalyze(selectedFile);
      onAnalysisComplete(result, previewUrl!);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unexpected error occurred');
    } finally {
      setIsAnalyzing(false);
    }
  };

  return (
    <div className="min-h-screen py-12 px-6">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="flex items-center gap-4 mb-8 animate-fade-in-up">
          <button
            onClick={onBack}
            className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-full transition-colors"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Upload Chest X-Ray</h1>
            <p className="text-gray-600 mt-1">Select a clear chest X-ray image for analysis</p>
          </div>
        </div>

        <div className="grid lg:grid-cols-2 gap-8">
          {/* Upload Area */}
          <div className="space-y-6 animate-slide-in-right">
            <div
              className={`medical-card rounded-2xl p-8 border-2 border-dashed transition-all duration-300 cursor-pointer ${
                isDragOver 
                  ? 'border-blue-400 bg-blue-50' 
                  : selectedFile 
                    ? 'border-green-400 bg-green-50' 
                    : 'border-gray-300 hover:border-blue-400 hover:bg-blue-50'
              }`}
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
              onClick={() => fileInputRef.current?.click()}
            >
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                onChange={handleFileInputChange}
                className="hidden"
              />
              
              <div className="text-center">
                {selectedFile ? (
                  <FileImage className="w-16 h-16 text-green-600 mx-auto mb-4" />
                ) : (
                  <Upload className="w-16 h-16 text-gray-400 mx-auto mb-4" />
                )}
                
                <h3 className="text-lg font-semibold mb-2">
                  {selectedFile ? 'File Selected' : 'Drop your X-ray image here'}
                </h3>
                <p className="text-gray-600 mb-4">
                  {selectedFile ? selectedFile.name : 'or click to browse files'}
                </p>
                
                <div className="flex flex-wrap gap-2 justify-center text-sm text-gray-500">
                  <span className="bg-gray-100 px-3 py-1 rounded-full">JPG</span>
                  <span className="bg-gray-100 px-3 py-1 rounded-full">PNG</span>
                  <span className="bg-gray-100 px-3 py-1 rounded-full">JPEG</span>
                </div>
              </div>
            </div>

            {error && (
              <div className="flex items-center gap-2 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
                <AlertCircle className="w-5 h-5" />
                <span>{error}</span>
              </div>
            )}

            <button
              onClick={handleAnalyze}
              disabled={!selectedFile || isAnalyzing}
              className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 disabled:from-gray-400 disabled:to-gray-500 text-white font-semibold py-4 px-6 rounded-xl shadow-lg hover:shadow-xl transform hover:scale-105 disabled:transform-none transition-all duration-300 flex items-center justify-center gap-3"
            >
              {isAnalyzing ? (
                <>
                  <Loader className="w-5 h-5 animate-spin" />
                  Analyzing...
                </>
              ) : (
                <>
                  <FileImage className="w-5 h-5" />
                  Analyze X-Ray
                </>
              )}
            </button>
          </div>

          {/* Preview Area */}
          <div className="animate-slide-in-right" style={{ animationDelay: '0.2s' }}>
            <div className="medical-card rounded-2xl p-6">
              <h3 className="text-lg font-semibold mb-4">Image Preview</h3>
              <div className="aspect-square bg-gray-100 rounded-xl overflow-hidden">
                {previewUrl ? (
                  <img
                    src={previewUrl}
                    alt="X-ray preview"
                    className="w-full h-full object-contain"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <div className="text-center text-gray-400">
                      <FileImage className="w-16 h-16 mx-auto mb-4" />
                      <p>No image selected</p>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Instructions */}
            <div className="mt-6 p-6 bg-blue-50 rounded-xl">
              <h4 className="font-semibold text-blue-900 mb-3">Tips for Best Results:</h4>
              <ul className="space-y-2 text-sm text-blue-800">
                <li className="flex items-start gap-2">
                  <div className="w-1.5 h-1.5 bg-blue-600 rounded-full mt-2 flex-shrink-0"></div>
                  Use high-quality, clear chest X-ray images
                </li>
                <li className="flex items-start gap-2">
                  <div className="w-1.5 h-1.5 bg-blue-600 rounded-full mt-2 flex-shrink-0"></div>
                  Ensure the entire chest area is visible
                </li>
                <li className="flex items-start gap-2">
                  <div className="w-1.5 h-1.5 bg-blue-600 rounded-full mt-2 flex-shrink-0"></div>
                  Avoid blurry or poorly lit images
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default UploadScreen;