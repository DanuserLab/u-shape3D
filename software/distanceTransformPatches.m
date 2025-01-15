function distanceOnMesh = distanceTransformPatches(watersheds, neighbors)

% distanceTransformPatches - given a segmented mesh, for each face finds the distance to the edge of the nearest segmented patch 
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

% initialize a distance matrix for the mesh
distanceOnMesh = inf(length(watersheds),1);

% iterate through the distances from the edge of the watershed until none remain
curDist = 0;
onBoundary = 1;
while max(onBoundary) == 1
    
    % find the faces on the edge of the watersheds
    onBoundary = logical(findBoundaryFaces(watersheds, neighbors, 'single'));
    
    % update the distance matrix
    distanceOnMesh(onBoundary) = curDist;
    curDist = curDist + 1;
    
    % shrink the watersheds
    watersheds(onBoundary) = 0;

end