function pairStats = calculatePairStats(patchPairs, surface, surfaceSegment, neighbors, meanCurvature, meanCurvatureUnsmoothed, gaussCurvature)

% calculatePairStats - for the list of adjacent patch pairs provided, calculates various statistics
%
% Copyright (C) 2019, Danuser Lab - UTSouthwestern 
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

% find the boundary faces
onBoundary = findBoundaryFaces(surfaceSegment, neighbors, 'single');

% measure the area of each face
areas = measureAllFaceAreas(surface); 

% calculate the principal curvatures
kappa1 = real(-1*meanCurvatureUnsmoothed + sqrt(meanCurvatureUnsmoothed.^2-gaussCurvature));
kappa2 = real(-1*meanCurvatureUnsmoothed - sqrt(meanCurvatureUnsmoothed.^2-gaussCurvature));

% calculate curvature statistics
curvatureStats.meanCurvature = mean(meanCurvature);
curvatureStats.stdCurvature = std(meanCurvature);
curvatureStats.curvature20 = prctile(meanCurvature,20);
curvatureStats.curvature80 = prctile(meanCurvature,80);
curvatureStats.gaussCurvature20 = prctile(gaussCurvature,20);
curvatureStats.gaussCurvature80 = prctile(gaussCurvature,80);
curvatureStats.curvature10 = prctile(meanCurvature,10);
curvatureStats.curvature90 = prctile(meanCurvature,90);

% remove 0s from measures to prevent division by zero
%segmentStats.surfaceArea(segmentStats.surfaceArea == 0) = 1;
%segmentStats.closureSurfaceArea(segmentStats.closureSurfaceArea == 0) = 1;

% save the list of patch pairs
pairStats.patchPairs = patchPairs;

% iterate through the patch pairs
for p = 1:size(patchPairs,1)
    
    % calculate the stats for an indivdual pair
    statsOnePair = calculatePairStatsOnePair(patchPairs(p,1), patchPairs(p,2), surface, surfaceSegment, neighbors, onBoundary, areas, meanCurvature, gaussCurvature, kappa1, kappa2, curvatureStats);
    
    % unpack the statistics
    pairStats = unpackStatisticsPairStats(statsOnePair, pairStats, p);
    
end
