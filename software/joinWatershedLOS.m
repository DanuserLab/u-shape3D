function joinedWatersheds = joinWatershedLOS(mesh, losRatio, raysPerCompare, neighbors, watersheds, local)

% joinWatershedLOS - joins watershed regions by iteratively merging neighboring regions if the regions are mutually visible
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

% Note that local has a slightly different meaning here than in calculateMutualVisibilityPair.m
if local == 1
    localDist = 9; %  the maximum length mutual visibility test ray allowed, measured in pixels
else
    localDist = Inf;
end

% make a graph of adjacent local watersheds (the last input controls if flat regions are included)
[watershedLabels, watershedGraph] = makeGraphFromLabel(neighbors, watersheds, 1); 

% construct an initial list of adjacent watersheds to consider merging
edgesToCheck = [];
for w = randperm(length(watershedGraph))
   
    % find the label of the region
    wLabel = watershedLabels(w);

    % 0 indicates an unsuccessful segmentation and a negative label indicates a flat region
    if wLabel < 1
        continue
    end 

    % find the label of its neighbors
    nLabels = watershedGraph{w};

    % return if there are no neighbors (because perhaps it is disjoint from the rest of the structure)
    if isempty(nLabels)
        continue
    end

    % remove 0 labels from the list of neighbors
    nLabels = nLabels(nLabels~=0);
    
    % add edges to the list of edges to check
    toAdd = [wLabel.*ones(length(nLabels),1), nLabels'];
    edgesToCheck = [edgesToCheck; toAdd]; 
end

% measure the positions of the faces
numFaces = size(neighbors,1);
positions = zeros(numFaces,3);
for f = 1:numFaces
    verticesFace = mesh.faces(f,:);
    positions(f,:) = (mesh.vertices(verticesFace(1),:) + mesh.vertices(verticesFace(2),:) + mesh.vertices(verticesFace(3),:))/3;
end

% calculate the mutual visibility between all pairs of adjacent watersheds found
mutVis = NaN(size(edgesToCheck,1),1);
disp(['Number of LOS pairs to measure ' num2str(length(edgesToCheck))])
parfor p = 1:size(edgesToCheck,1) 
    if mod(p,100) == 0, disp(['   pair ' num2str(p)]); end
    mutVis(p,1) = calculateMutualVisibilityPair(mesh, positions, watersheds, edgesToCheck(p,1), edgesToCheck(p,2), localDist/2, raysPerCompare, 1);
end
edgesToCheck(:,3) = mutVis(:,1);

% sort the edges by mutual visibility
edgesToCheck = sortrows(edgesToCheck, -3);

% merge regions until no adjacent regions exceed the visibility threshold
labelIndex = 1:length(watershedLabels);
while edgesToCheck(1,3) >= losRatio
    
    disp(['los ', num2str(length(unique(watersheds)))])
    
    % find the labels of the watershed regions
    mergeLabel = min(edgesToCheck(1,1:2));
    if mergeLabel < 0, mergeLabel = max(edgesToCheck(1,1:2)); end 
    mergeDestroy = setdiff(edgesToCheck(1,1:2), mergeLabel);
    
    % find the indices of the labels in watershedGraphs
    mergeLabelIndex = labelIndex(watershedLabels==mergeLabel);
    mergeDestroyIndex = labelIndex(watershedLabels==mergeDestroy);
    
    % make a list of watershed regions in which the two regions are merged 
    watershedsCombined = watersheds;    
    if mergeLabel==edgesToCheck(1,1)
        watershedsCombined(watersheds==edgesToCheck(1,2)) = mergeLabel;
    else
        watershedsCombined(watersheds==edgesToCheck(1,1)) = mergeLabel;
    end
    
    % update the list of watersheds indexed by face
    watersheds = watershedsCombined;
    
    % update watershedGraph, which lists the neighbors of each region
    neighborsOfDestroyed = watershedGraph{mergeDestroyIndex}; % find the neighbors of the desroyed label
    neighborsOfDestroyed = setdiff(neighborsOfDestroyed, mergeLabel);
    watershedGraph{mergeLabelIndex} = setdiff([watershedGraph{mergeLabelIndex}, neighborsOfDestroyed], [mergeLabel, mergeDestroy]); % update mergeLabel
    watershedGraph{mergeDestroyIndex} = []; % update the destroyed label
    for n = 1:length(neighborsOfDestroyed) % replace the destoyed label with the merged label in each of the destroyed neighbors lists of neighbors
        neighborIndex = labelIndex'.*(watershedLabels==neighborsOfDestroyed(n));
        neighborIndex = neighborIndex(neighborIndex~=0);
        watershedGraph{neighborIndex} = setdiff([watershedGraph{neighborIndex}, mergeLabel], mergeDestroy);
    end
    
    % remove all instances of both watersheds in the list of edges to check
    toRemove = logical( (edgesToCheck(:,1)==mergeLabel) + (edgesToCheck(:,2)==mergeLabel) + ...
        (edgesToCheck(:,1)==mergeDestroy) + (edgesToCheck(:,2)==mergeDestroy) );
    edgesToCheckFrom = edgesToCheck(:,1); edgesToCheckTo = edgesToCheck(:,2); mutVis = edgesToCheck(:,3);
    edgesToCheckFrom(toRemove) = []; edgesToCheckTo(toRemove) = []; mutVis(toRemove) = []; 
    edgesToCheck = [edgesToCheckFrom, edgesToCheckTo, mutVis];
    
    % remove the checked pair from the list of regions to check
    edgesToCheck(1,:) = [];
    
    % find a list of neighbors of the combined region to measure the mutual visibility
    nLabels = watershedGraph{mergeLabelIndex};
    edgesToAdd = [mergeLabel.*ones(length(nLabels),1), nLabels', NaN(length(nLabels),1)];
    
    % calculate the mutual visibility between all pairs of adjacent watersheds found
    mutVis = NaN(length(nLabels),1);
    parfor p = 1:size(edgesToAdd,1) 
        mutVis(p,1) = calculateMutualVisibilityPair(mesh, positions, watersheds, edgesToAdd(p,1), edgesToAdd(p,2), localDist/2, raysPerCompare, 1);
    end
    edgesToAdd(:,3) = mutVis(:,1);
    
    % update the list of edges to check
    edgesToCheck = [edgesToCheck; edgesToAdd];
    
    % sort the list of edges to check
    edgesToCheck = sortrows(edgesToCheck, -3);

end

joinedWatersheds = watersheds;

