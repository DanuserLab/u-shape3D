function triangleMeasure = calculateTriangleMeasurePair(mesh, watersheds, watershedLabels, neighbors, closureSurfaceArea, firstRegionIndex, secondRegionIndex, patchLength, meshLength)

% check to make sure that the patchLength isn't too large
%
% Copyright (C) 2025, Danuser Lab - UTSouthwestern 
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
if patchLength > 0.25*meshLength
    triangleMeasure = 0;
    return
end

% find the graph labels of the first two watersheds on the list
labelIndex = 1:length(watershedLabels);
gLabel1 = labelIndex(watershedLabels == firstRegionIndex);
gLabel2 = labelIndex(watershedLabels == secondRegionIndex);  

% make a list of watershed regions in which the two regions are merged 
watershedsCombined = watersheds;
mergeLabel = min([firstRegionIndex secondRegionIndex]);
if mergeLabel < 0, mergeLabel = max([firstRegionIndex secondRegionIndex]); end 
if mergeLabel == firstRegionIndex
    watershedsCombined(watersheds == secondRegionIndex) = mergeLabel;
else
    watershedsCombined(watersheds == firstRegionIndex) = mergeLabel;
end

% find the closure surface area of the combined region
[~, closureSurfaceAreaCombinedRegion, ~] = closeMesh(mergeLabel, mesh, watershedsCombined, neighbors);

% calculate the value of the triangle measure (inspired by the law of cosines)
triangleMeasure = (closureSurfaceArea(gLabel1)+closureSurfaceArea(gLabel2)-closureSurfaceAreaCombinedRegion)/(sqrt(closureSurfaceArea(gLabel1)*closureSurfaceArea(gLabel2)));
