import React from 'react';

interface ConfidenceChartProps {
  confidence: {
    PNEUMONIA: number;
    NORMAL: number;
  };
  probability?: number; // 0..1
  thresholdUsed?: number; // 0..1
}

const ConfidenceChart: React.FC<ConfidenceChartProps> = ({ confidence, probability, thresholdUsed }) => {
  const normalPercentage = confidence.NORMAL;
  const pneumoniaPercentage = confidence.PNEUMONIA;
  const probabilityPercent = probability !== undefined ? probability * 100 : undefined;
  const thresholdPercent = thresholdUsed !== undefined ? thresholdUsed * 100 : undefined;

  return (
    <div className="space-y-6">
      {/* Bar Chart */}
      <div className="space-y-4">
        <div>
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm font-medium text-green-700">NORMAL</span>
            <span className="text-sm font-bold text-green-700">{normalPercentage.toFixed(1)}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-3">
            <div 
              className="bg-gradient-to-r from-green-500 to-green-600 h-3 rounded-full transition-all duration-1000 ease-out"
              style={{ width: `${normalPercentage}%` }}
            ></div>
          </div>
        </div>

        <div>
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm font-medium text-red-700">PNEUMONIA</span>
            <span className="text-sm font-bold text-red-700">{pneumoniaPercentage.toFixed(1)}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-3">
            <div 
              className="bg-gradient-to-r from-red-500 to-red-600 h-3 rounded-full transition-all duration-1000 ease-out"
              style={{ width: `${pneumoniaPercentage}%`, animationDelay: '0.5s' }}
            ></div>
          </div>
        </div>
      </div>

      {/* Pie Chart */}
      <div className="flex justify-center">
        <div className="relative w-40 h-40">
          <svg className="w-full h-full transform -rotate-90" viewBox="0 0 42 42">
            <circle
              cx="21"
              cy="21"
              r="15.915"
              fill="transparent"
              stroke="#e5e7eb"
              strokeWidth="3"
            />
            <circle
              cx="21"
              cy="21"
              r="15.915"
              fill="transparent"
              stroke="#10b981"
              strokeWidth="3"
              strokeDasharray={`${normalPercentage} ${100 - normalPercentage}`}
              strokeDashoffset="25"
              className="transition-all duration-1000 ease-out"
            />
            <circle
              cx="21"
              cy="21"
              r="15.915"
              fill="transparent"
              stroke="#ef4444"
              strokeWidth="3"
              strokeDasharray={`${pneumoniaPercentage} ${100 - pneumoniaPercentage}`}
              strokeDashoffset={`${25 - normalPercentage}`}
              className="transition-all duration-1000 ease-out"
              style={{ animationDelay: '0.5s' }}
            />
          </svg>
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="text-center">
              <div className="text-lg font-bold text-white">
                {Math.max(normalPercentage, pneumoniaPercentage).toFixed(0)}%
              </div>
              <div className="text-xs text-gray-600">Confidence</div>
            </div>
          </div>
        </div>
      </div>

      {/* Radial Gauge: Probability vs Threshold */}
      {(probabilityPercent !== undefined && thresholdPercent !== undefined) && (
        <div className="medical-card rounded-2xl p-4">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm font-semibold text-gray-800">Probability vs Threshold</h3>
            <div className="text-xs text-gray-500">Higher is more confident</div>
          </div>
          <div className="flex items-center gap-6">
            <div className="relative w-28 h-28">
              <svg className="w-full h-full transform -rotate-90" viewBox="0 0 42 42">
                <circle cx="21" cy="21" r="15.915" fill="transparent" stroke="#e5e7eb" strokeWidth="3" />
                {/* Threshold ring */}
                <circle
                  cx="21" cy="21" r="15.915" fill="transparent"
                  stroke="#94a3b8" strokeWidth="3"
                  strokeDasharray={`${thresholdPercent} ${100 - thresholdPercent}`}
                  strokeDashoffset="25"
                  className="transition-all duration-700 ease-out opacity-70"
                />
                {/* Probability ring */}
                <circle
                  cx="21" cy="21" r="15.915" fill="transparent"
                  stroke="#6366f1" strokeWidth="3"
                  strokeDasharray={`${probabilityPercent} ${100 - probabilityPercent}`}
                  strokeDashoffset="25"
                  className="transition-all duration-700 ease-out"
                  style={{ filter: 'drop-shadow(0 1px 2px rgba(99,102,241,0.35))' }}
                />
              </svg>
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="text-center">
                  <div className="text-base font-bold text-white">{probabilityPercent.toFixed(0)}%</div>
                  <div className="text-[10px] text-gray-500">Probability</div>
                </div>
              </div>
            </div>
            <div className="flex-1 space-y-2">
              <div className="flex items-center justify-between text-xs">
                <span className="text-gray-600">Threshold</span>
                <span className="font-semibold text-gray-800">{thresholdPercent.toFixed(1)}%</span>
              </div>
              <div className="w-full h-2 bg-gray-200 rounded-full overflow-hidden">
                <div className="h-2 bg-gradient-to-r from-slate-400 to-slate-500" style={{ width: `${thresholdPercent}%` }} />
              </div>
              <div className="flex items-center justify-between text-xs">
                <span className="text-gray-600">Probability</span>
                <span className="font-semibold text-indigo-700">{probabilityPercent.toFixed(1)}%</span>
              </div>
              <div className="w-full h-2 bg-gray-200 rounded-full overflow-hidden">
                <div className="h-2 bg-gradient-to-r from-indigo-500 to-indigo-600" style={{ width: `${probabilityPercent}%` }} />
              </div>
              <div className="text-xs mt-1">
                {probabilityPercent >= thresholdPercent ? (
                  <span className="px-2 py-1 rounded-full bg-green-100 text-green-700 font-medium">Above threshold</span>
                ) : (
                  <span className="px-2 py-1 rounded-full bg-yellow-100 text-yellow-700 font-medium">Below threshold</span>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Legend */}
      <div className="flex justify-center space-x-6 text-sm">
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 bg-green-500 rounded-full"></div>
          <span>Normal</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 bg-red-500 rounded-full"></div>
          <span>Pneumonia</span>
        </div>
      </div>
    </div>
  );
};

export default ConfidenceChart;