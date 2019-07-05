function regionCenters = findRegionCentersFarthest(neighbors, watersheds, measure)

% findWatershedCentersFarthest - finds the face within each watershed that is farthest from the patch edge
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


% for each face, find the distance to a region boundary
boundaryDist = findDistToRegionEdge(watersheds, neighbors);

% finds a list of the region labels
regions = unique(watersheds);
regions = regions(regions>0);

% iterate through the regions
regionCenters = zeros(length(regions),2);
for w = 1:length(regions)
    
    % find the watershed label
    label = regions(w);
    
    % append the global watershed label to the matrix
    regionCenters(w,2) = label;
    
    % find the maximum distance in the region
    maxDist = max(boundaryDist.*(watersheds==label));
    
    % if there is more than one face at a maximum distance from the edge, chose the face with the lowest value of the measure
    maxDistsInRegion = logical((boundaryDist==maxDist).*(watersheds==label));
    [~, regionCenters(w,1)] = min(measure.*maxDistsInRegion);
    
end
