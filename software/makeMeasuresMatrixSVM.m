function [measures, names] = makeMeasuresMatrixSVM(stats, cellStats, inModel, weinerEstimateList, channel, frame, pixelSize)

% makeMeasuresMatrixSVM - outputs measures for training an SVM or applying an SVM model (simply stores the measure list in one place)
%
% Copyright (C) 2024, Danuser Lab - UTSouthwestern 
%
% This file is part of Morphology3DPackage.
% 
% Morphology3DPackage is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% Morphology3DPackage is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with Morphology3DPackage.  If not, see <http://www.gnu.org/licenses/>.
% 
% 

% calculate conversion factors
lengthConvert = pixelSize/1000;
curvatureConvert = -1000/pixelSize;

% remove zeros and NaNs from some measures to prevent NaNs
stats{channel,frame}.closureSurfaceArea(stats{channel,frame}.closureSurfaceArea == 0) = 1;
stats{channel,frame}.radius(stats{channel,frame}.radius == 0) = 1;
stats{channel,frame}.radius(isnan(stats{channel,frame}.radius)) = 1;
stats{channel,frame}.surfaceArea(stats{channel,frame}.surfaceArea == 0) = 1;

% make the measures matrix
measures = NaN(length(stats{channel,frame}.surfaceArea), 23);
measures(:,1) = stats{channel,frame}.surfaceArea*lengthConvert^2; names{1} = 'surface area';
measures(:,2) = stats{channel,frame}.surfaceArea./stats{channel,frame}.closureSurfaceArea; names{2} = 'surface area/closure surface area';
measures(:,3) = stats{channel,frame}.minCurvature*curvatureConvert; names{3} = 'maximum curvature';
measures(:,4) = stats{channel,frame}.meanCurvature*curvatureConvert; names{4} = 'mean curvature';
measures(:,5) = stats{channel,frame}.stdCurvature*curvatureConvert*-1; names{5} = 'std of curvature';
measures(:,6) = stats{channel,frame}.volume*lengthConvert^3; names{6} = 'volume';
measures(:,7) = stats{channel,frame}.volume./stats{channel,frame}.closureSurfaceArea.^(3/2); names{7} = 'volume/closure surface area';
measures(:,8) = stats{channel,frame}.perimeter*lengthConvert; names{8} = 'perimeter';
measures(:,9) = stats{channel,frame}.radius*lengthConvert; names{9} = 'radius';
measures(:,10) = stats{channel,frame}.nonFlatCircularity; names{10} = 'non-flat-circularity';
measures(:,11) = stats{channel,frame}.variationFromSphere; names{11} = 'variation from a sphere';
measures(:,12) = stats{channel,frame}.meanCurvatureOnEdge*curvatureConvert; names{12} = 'mean curvature on protrusion edge';
measures(:,13) = stats{channel,frame}.meanGaussCurvature*curvatureConvert.^2; names{13} = 'mean Gaussian curvature';
measures(:,14) = sqrt(sum((stats{channel,frame}.weightedMeanPosition - stats{channel,frame}.unWeightedMeanPosition).^2,2))./stats{channel,frame}.radius; names{14} = 'normalized weighted minus unweighted mean position';
measures(:,15) = sqrt(sum((stats{channel,frame}.closeCenter - stats{channel,frame}.unWeightedMeanPosition).^2,2))./stats{channel,frame}.radius; names{15} = 'normalized close center minus unweighted mean position';
measures(:,16) = cellStats{channel,frame}.blebCount; names{16} = 'protrusion count';
measures(:,17) = cellStats{channel,frame}.cellVolume*lengthConvert^3; names{17} = 'cell volume';
measures(:,18) = cellStats{channel,frame}.cellSurfaceArea*lengthConvert^2; names{18} = 'cell surface area';
measures(:,19) = sqrt(sum((stats{channel,frame}.closeCenter - stats{channel,frame}.weightedMeanPosition).^2,2))./stats{channel,frame}.radius; names{19} = 'normalized close center minus weighted mean position';
measures(:,20) = sqrt(sum((stats{channel,frame}.closeCenter - stats{channel,frame}.unWeightedMeanPosition).^2,2)); names{20} = 'close center minus unweighted mean position';
measures(:,21) = stats{channel,frame}.closureSurfaceArea*lengthConvert^2; names{21} = 'closure surface area';
measures(:,22) = stats{channel,frame}.radius./sqrt(stats{channel,frame}.surfaceArea); names{22} = 'radius / surface area';
measures(:,23) = stats{channel,frame}.sdf; names{23} = 'shape diameter function';

% if the closeCenter is not defined, set the resultant measures to zero
measures(isnan(measures(:,15)),15) = 0;
measures(isnan(measures(:,19)),19) = 0;
measures(isnan(measures(:,20)),20) = 0;

% if the meanCurvatureOnEdge is not defined, set the resultant measures to be zero
measures(isnan(measures(:,12)),12) = 0;

% find the measures to include
if ischar(inModel) && (strcmp(inModel, 'all') || strcmp(inModel, 'All'))
    inModel = ones(1,size(measures,2));
end

% select the picked features
selectedMeasures = [];
for m = 1:min([length(inModel), size(measures, 2)])
    if inModel(m) == 1
        selectedMeasures = [selectedMeasures, measures(:,m)];
    end
end
measures = selectedMeasures;
