function [spillDepths, spillNeighbors, ridgeHeights] = measureDepthsAll(faceNeighbors, watersheds, watershedLabels, watershedGraph, measure)

% measureDepthsAll - measure the depth and spillover neighbor for each watershed region
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


% initialize matrices
numWatersheds = length(watershedLabels);
spillDepths = Inf(numWatersheds, 1);
spillNeighbors = zeros(numWatersheds, 1);
ridgeHeights = zeros(numWatersheds, 1);

% iterate through the regions
for w = 1:numWatersheds
    
    % measure the spill depth and spill neighbor for the region
    [spillDepths(w,1), spillNeighbors(w,1), ridgeHeights(w,1)] = measureDepthOneRegion(w, faceNeighbors, watersheds, watershedLabels, watershedGraph, measure);
 
end
