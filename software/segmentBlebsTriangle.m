function [joinedWatersheds, joinedWatershedsSpill, watersheds] = segmentBlebsTriangle(surface, curvature, neighbors, otsuRatio, triangleRatio)

% segment blebs from curvature using a watershed algorithm and then merging watersheds in two ways
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

% caclulate an Otsu threshold level for positive curvature
curvatureThreshold = -1*graythresh(-1*curvature(curvature<0));

% perform a watershed segmentation of curvature on the mesh
watersheds = labelWatersheds(neighbors, curvature); 
% 
% % label flat regions (regions without a face above the curvature threshold)
% watersheds = joinFlatRegions(curvatureThreshold, rawWatersheds, curvature); 

% merge watershed regions using a spill depth criterion
joinedWatershedsSpill = joinWatershedSpillDepth(-1*otsuRatio*curvatureThreshold, neighbors, watersheds, curvature, 0, 0);
     
% merge watershed regions using a triangle ratio criterion   
joinedWatersheds = joinWatershedTriangle(surface, triangleRatio, neighbors, joinedWatershedsSpill); 
