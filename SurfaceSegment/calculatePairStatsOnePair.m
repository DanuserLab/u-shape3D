function pairStats = calculatePairStatsOnePair(patch1, patch2, surface, surfaceSegment, neighbors, onBoundary, areas, meanCurvature, gaussCurvature, kappa1, kappa2, curvatureStatsGlobal)

% calculatePairStatsOnePair - given two adjacent patches, calculates statistics about them
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


% account for the sign error in mean curvature
meanCurvature = -1*meanCurvature;

% find faces near the interface
bothPatches = (surfaceSegment == patch1) | (surfaceSegment == patch2);
neighborsIn1 = NaN(length(surfaceSegment),1); neighborsIn2 = NaN(length(surfaceSegment),1); 
for f = 1:length(surfaceSegment)
    neighborsIn1(f) = (surfaceSegment(f)==patch1) && ( surfaceSegment(neighbors(f,1))==patch2 || surfaceSegment(neighbors(f,2))==patch2 || surfaceSegment(neighbors(f,3))==patch2 );
    neighborsIn2(f) = (surfaceSegment(f)==patch2) && ( surfaceSegment(neighbors(f,1))==patch1 || surfaceSegment(neighbors(f,2))==patch1 || surfaceSegment(neighbors(f,3))==patch1 );
end
neighborsInEither = neighborsIn1 | neighborsIn2;

% find curvature statistics for the two patches
curvatureStatsLocal.meanCurvature = mean(meanCurvature(bothPatches));
curvatureStatsLocal.stdCurvature = std(meanCurvature(bothPatches));
curvatureStatsLocal.curvature20 = prctile(meanCurvature(bothPatches),20);
curvatureStatsLocal.curvature80 = prctile(meanCurvature(bothPatches),80);
curvatureStatsLocal.gaussCurvature20 = prctile(gaussCurvature(bothPatches),20);
curvatureStatsLocal.gaussCurvature80 = prctile(gaussCurvature(bothPatches),80);

% find the index into segmentStats for both patches
% ssIndexPatch1 = find(segmentStats.index==patch1, 1);
% ssIndexPatch2 = find(segmentStats.index==patch2, 1);

% find the mean curvature at the boundary
pairStats.meanCurvature = mean(meanCurvature(neighborsInEither));
pairStats.meanGaussCurvature = mean(gaussCurvature(neighborsInEither));
pairStats.meanCurvatureNormal = mean(meanCurvature(neighborsInEither)) - curvatureStatsLocal.meanCurvature;

% find the max curvature at the boundary
pairStats.maxCurvature = max(meanCurvature(neighborsInEither));
pairStats.maxCurvatureNormal = max(meanCurvature(neighborsInEither)) - max(meanCurvature(bothPatches));

% find the std of curvature at the boundary
pairStats.stdCurvature = std(meanCurvature(neighborsInEither));
pairStats.stdGaussCurvature = std(gaussCurvature(neighborsInEither));

% find the fraction of low and high curvatures at the boundary
pairStats.fractionHighCurvatureGlobal = mean(meanCurvature(neighborsInEither) > curvatureStatsGlobal.curvature80);
pairStats.fractionLowCurvatureGlobal = mean(meanCurvature(neighborsInEither) < curvatureStatsGlobal.curvature20);
pairStats.fractionHighCurvatureLocal = mean(meanCurvature(neighborsInEither) > curvatureStatsLocal.curvature80);
pairStats.fractionLowCurvatureLocal = mean(meanCurvature(neighborsInEither) < curvatureStatsLocal.curvature20);
pairStats.fractionHighGaussCurvatureGlobal = mean(gaussCurvature(neighborsInEither) > curvatureStatsGlobal.gaussCurvature80);
pairStats.fractionLowGaussCurvatureGlobal = mean(gaussCurvature(neighborsInEither) < curvatureStatsGlobal.gaussCurvature20);
pairStats.fractionHighGaussCurvatureLocal = mean(gaussCurvature(neighborsInEither) > curvatureStatsLocal.gaussCurvature80);
pairStats.fractionLowGaussCurvatureLocal = mean(gaussCurvature(neighborsInEither) < curvatureStatsLocal.gaussCurvature20);
pairStats.fractionVeryHighCurvatureGlobal = mean(meanCurvature(neighborsInEither) > curvatureStatsGlobal.curvature90);
pairStats.fractionVeryLowCurvatureGlobal = mean(meanCurvature(neighborsInEither) < curvatureStatsGlobal.curvature10);

% percentage total perimeter
pairStats.fractionTotalPerimeter = (sum(neighborsIn1)+sum(neighborsIn2))./sum(logical(onBoundary) & logical(bothPatches));
%pairStats.intersectionLengthOverDistanceBetweenEnds
%pairStats.smoothedIntersectionLengthOverDistanceBetweenEnds

% differances and means of various curvature patch parameters
pairStats.meanCurvatureDif = abs(mean(meanCurvature(surfaceSegment == patch1)) - mean(meanCurvature(surfaceSegment == patch1)));
pairStats.meanCurvatureMean = 0.5*(mean(meanCurvature(surfaceSegment == patch1)) + mean(meanCurvature(surfaceSegment == patch1)));
pairStats.maxCurvatureDif = abs(max(meanCurvature(surfaceSegment == patch1)) - max(meanCurvature(surfaceSegment == patch1)));
pairStats.maxCurvatureMean = 0.5*(max(meanCurvature(surfaceSegment == patch1)) + max(meanCurvature(surfaceSegment == patch1)));

% calculate patch statistics to calculate pair statistics
area1 = sum(areas(surfaceSegment==patch1)); area1(area1==0) = 1;
area2 = sum(areas(surfaceSegment==patch2)); area2(area2==0) = 1;
[~, closureArea1, closedMesh1, ~] = closeMesh(patch1, surface, surfaceSegment, neighbors); closureArea1(closureArea1==0) = 1;
[~, closureArea2, closedMesh2, ~] = closeMesh(patch2, surface, surfaceSegment, neighbors); closureArea2(closureArea2==0) = 1;
volume1 = measureMeshVolume(closedMesh1); 
volume2 = measureMeshVolume(closedMesh2);
perimeter1 = measureRegionPerimeter(surface, surfaceSegment, neighbors, onBoundary, patch1);
perimeter2 = measureRegionPerimeter(surface, surfaceSegment, neighbors, onBoundary, patch2);

% differances and means of various non-curvature patch parameters
pairStats.nonFlatCircularityDif = abs(closureArea1/perimeter1^2 - closureArea2/perimeter2^2);
pairStats.nonFlatCircularityMean = 0.5*(closureArea1/perimeter1^2 + closureArea2/perimeter2^2);
pairStats.volumeOverSurfaceAreaDif = abs(volume1/area1^1.5 - volume2/area2^1.5);
pairStats.volumeOverSurfaceAreaMean = 0.5*(volume1/area1^1.5 + volume2/area2^1.5);
pairStats.volumeOverClosureAreaDif = abs(volume1/closureArea1^1.5 - volume2/closureArea2^1.5);
pairStats.volumeOverClosureAreaMean = 0.5*(volume1/closureArea1^1.5 + volume2/closureArea2^1.5);

% consider the principal curvatures
kappaCutoff = curvatureStatsGlobal.stdCurvature; kappaHigh = 4;
kappaLocal1 = kappa1(neighborsInEither);
kappaLocal2 = kappa2(neighborsInEither);
pairStats.percentageRidgeLike = mean(kappaLocal1>=kappaCutoff & kappaLocal2<kappaCutoff & kappaLocal2>-kappaCutoff);
pairStats.percentageVeryRidgeLike = mean(kappaLocal1>=kappaHigh*kappaCutoff & kappaLocal2<kappaCutoff & kappaLocal2>-kappaCutoff);
pairStats.percentageValleyLike = mean(kappaLocal1<kappaCutoff & kappaLocal1>-kappaCutoff & kappaLocal2<=-kappaCutoff);
pairStats.percentageVeryValleyLike = mean(kappaLocal1<kappaCutoff & kappaLocal1>-kappaCutoff & kappaLocal2<=-kappaHigh*kappaCutoff);
pairStats.percentageDomed = mean(kappaLocal1>=kappaCutoff & kappaLocal2>=kappaCutoff);
pairStats.percentageCratered = mean(kappaLocal1<-kappaCutoff & kappaLocal2<-kappaCutoff);
pairStats.percentageFlat = mean(kappaLocal1<kappaCutoff & kappaLocal1>-kappaCutoff & kappaLocal2<kappaCutoff & kappaLocal2>-kappaCutoff);
pairStats.percentageSaddle = mean(kappaLocal1>=kappaCutoff & kappaLocal2<=-kappaCutoff);
