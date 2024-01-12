function patchPairs = findAdjacentPatchPairs(surfaceSegment, neighbors)

% findAdjacentPatchPairs - given a mesh segmentation into patches, makes a list of adjacent patches
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


% make a graph of adjacent local patches (the last input controls if flat regions are included)
[watershedLabels, watershedGraph] = makeGraphFromLabel(neighbors, surfaceSegment, 1); 

% construct an initial list of adjacent patches to consider merging
patchPairs = [];
for w = randperm(length(watershedGraph))
   
    % find the label of the region
    wLabel = watershedLabels(w);

    % 0 indicates an unsuccessful segmentation and a negative label indicates a flat region
    if wLabel < 1
        continue
    end 

    % find the labels of its neighbors
    nLabels = watershedGraph{w};

    % return if there are no neighbors (because perhaps it is disjoint from the rest of the structure)
    if isempty(nLabels)
        continue
    end

    % remove 0 labels from the list of neighbors
    nLabels = nLabels(nLabels~=0);
    
    % add edges to the list of edges to check
    toAdd = [wLabel.*ones(length(nLabels),1), nLabels'];
    patchPairs = [patchPairs; toAdd]; 
end
