function pairStats = unpackStatisticsPairStats(statsOnePair, pairStats, p)

% unpackStatisticsPairStats - assigns statsOnePair to be the pth element of every statistic in pairStats (very specific to calculatePairStats.m)
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

pairStats.meanCurvature(p) = statsOnePair.meanCurvature;
pairStats.meanGaussCurvature(p) = statsOnePair.meanGaussCurvature;
pairStats.meanCurvatureNormal(p) = statsOnePair.meanCurvatureNormal;
pairStats.maxCurvature(p) = statsOnePair.maxCurvature;
pairStats.maxCurvatureNormal(p) = statsOnePair.maxCurvatureNormal;
pairStats.stdCurvature(p) = statsOnePair.stdCurvature;
pairStats.stdGaussCurvature(p) = statsOnePair.stdGaussCurvature;

pairStats.fractionHighCurvatureGlobal(p) = statsOnePair.fractionHighCurvatureGlobal;
pairStats.fractionLowCurvatureGlobal(p) = statsOnePair.fractionLowCurvatureGlobal;
pairStats.fractionHighCurvatureLocal(p) = statsOnePair.fractionHighCurvatureLocal;
pairStats.fractionLowCurvatureLocal(p) = statsOnePair.fractionLowCurvatureLocal;
pairStats.fractionHighGaussCurvatureGlobal(p) = statsOnePair.fractionHighGaussCurvatureGlobal;
pairStats.fractionLowGaussCurvatureGlobal(p) = statsOnePair.fractionLowGaussCurvatureGlobal;
pairStats.fractionHighGaussCurvatureLocal(p) = statsOnePair.fractionHighGaussCurvatureLocal;
pairStats.fractionLowGaussCurvatureLocal(p) = statsOnePair.fractionLowGaussCurvatureLocal;
pairStats.fractionVeryHighCurvatureGlobal(p) = statsOnePair.fractionVeryHighCurvatureGlobal;
pairStats.fractionVeryLowCurvatureGlobal(p) = statsOnePair.fractionVeryLowCurvatureGlobal;

pairStats.fractionTotalPerimeter(p) = statsOnePair.fractionTotalPerimeter;

pairStats.meanCurvatureDif(p) = statsOnePair.meanCurvatureDif;
pairStats.maxCurvatureDif(p) = statsOnePair.maxCurvatureDif;
pairStats.nonFlatCircularityDif(p) = statsOnePair.nonFlatCircularityDif;
pairStats.volumeOverSurfaceAreaDif(p) = statsOnePair.volumeOverSurfaceAreaDif;
pairStats.volumeOverClosureAreaDif(p) = statsOnePair.volumeOverClosureAreaDif;

pairStats.meanCurvatureMean(p) = statsOnePair.meanCurvatureMean;
pairStats.maxCurvatureMean(p) = statsOnePair.maxCurvatureMean;
pairStats.nonFlatCircularityMean(p) = statsOnePair.nonFlatCircularityMean;
pairStats.volumeOverSurfaceAreaMean(p) = statsOnePair.volumeOverSurfaceAreaMean;
pairStats.volumeOverClosureAreaMean(p) = statsOnePair.volumeOverClosureAreaMean;

pairStats.percentageRidgeLike(p) = statsOnePair.percentageRidgeLike;
pairStats.percentageVeryRidgeLike(p) = statsOnePair.percentageVeryRidgeLike;
pairStats.percentageValleyLike(p) = statsOnePair.percentageValleyLike;
pairStats.percentageVeryValleyLike(p) = statsOnePair.percentageVeryValleyLike;
pairStats.percentageDomed(p) = statsOnePair.percentageDomed;
pairStats.percentageCratered(p) = statsOnePair.percentageCratered;
pairStats.percentageFlat(p) = statsOnePair.percentageFlat;
pairStats.percentageSaddle(p) = statsOnePair.percentageSaddle;
