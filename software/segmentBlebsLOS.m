function [joinedWatersheds, joinedWatershedsSpill, rawWatersheds] = segmentBlebsLOS(surface, curvature, neighbors, otsuRatio, triangleRatio, losRatio, raysPerCompare)

% segment blebs from curvature using a watershed algorithm and then LOS merging
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

% perform a watershed segmentation of curvature on the mesh
rawWatersheds = labelWatersheds(neighbors, curvature); 

% caclulate an Otsu threshold level for positive curvature
curvatureThreshold = -1*graythresh(-1*curvature(curvature<0));

% merge watershed regions using a spill depth criterion
joinedWatershedsSpill = joinWatershedSpillDepth(-1*otsuRatio*curvatureThreshold, neighbors, rawWatersheds, curvature, 0, 0);

% merge watershed regions using a line-of-sight algorithm
joinedWatersheds = joinWatershedLOS(surface, losRatio, raysPerCompare, neighbors, joinedWatershedsSpill, 0);
