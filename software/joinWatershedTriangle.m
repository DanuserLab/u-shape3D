function joinedWatersheds = joinWatershedTriangle(mesh, triangleRatio, neighbors, watersheds) 

% joinWatershedTriangle - joins watershed regions by iteratively merging regions if doing so reduces the closure surface area by more than areaRatio times the initial net closure surface area
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

% make a graph of adjacent local watersheds
[watershedLabels, watershedGraph] = makeGraphFromLabel(neighbors, watersheds, 1); 

% measure the closure surface area of each region
closureSurfaceArea = NaN(length(watershedLabels),1);
for w = 1:length(watershedLabels)
    if watershedLabels(w) ~= 0
        [~, closureSurfaceArea(w), ~] = closeMesh(watershedLabels(w), mesh, watersheds, neighbors);
    end
end

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

% check if regions should be merged until there are no more region pairs left on the list
labelIndex = 1:length(watershedLabels);
while ~isempty(edgesToCheck)
    
    % find the graph labels of the first two watersheds on the list
    gLabel1 = labelIndex(watershedLabels==edgesToCheck(1,1));
    gLabel2 = labelIndex(watershedLabels==edgesToCheck(1,2));  
    
    % make a list of watershed regions in which the two regions are merged 
    watershedsCombined = watersheds;
    mergeLabel = min(edgesToCheck(1,:)); % label the combined region with the lower of the two labels as long as it is positive
    if mergeLabel < 0, mergeLabel = max(edgesToCheck(1,:)); end 
    if mergeLabel==edgesToCheck(1,1)
        watershedsCombined(watersheds==edgesToCheck(1,2)) = mergeLabel;
    else
        watershedsCombined(watersheds==edgesToCheck(1,1)) = mergeLabel;
    end
    
    % find the closure surface area of the combined region
    [~, closureSurfaceAreaCombinedRegion, ~] = closeMesh(mergeLabel, mesh, watershedsCombined, neighbors);
    
    % calculate the value of the triangle measure (inspired by the law of cosines)
    triangleMeasure = (closureSurfaceArea(gLabel1)+closureSurfaceArea(gLabel2)-closureSurfaceAreaCombinedRegion)/(sqrt(closureSurfaceArea(gLabel1)*closureSurfaceArea(gLabel2)));

    % merge the regions
    if triangleMeasure > triangleRatio  

        % find the label of the destroyed watershed
        mergeDestroy = setdiff(edgesToCheck(1,:), mergeLabel);
        
        % find the indices of the labels in watershedGraphs
        mergeLabelIndex = labelIndex(watershedLabels==mergeLabel);
        mergeDestroyIndex = labelIndex(watershedLabels==mergeDestroy);
            
        % update the list of watersheds indexed by face
        watersheds = watershedsCombined;
       
        % update watershedGraph, which lists the neighbors of each region (this is as in joinWatershedSpillDepth and should perhaps be merged)
        neighborsOfDestroyed = watershedGraph{mergeDestroyIndex}; % find the neighbors of the desroyed label
        neighborsOfDestroyed = setdiff(neighborsOfDestroyed, mergeLabel);
        watershedGraph{mergeLabelIndex} = setdiff([watershedGraph{mergeLabelIndex}, neighborsOfDestroyed], [mergeLabel, mergeDestroy]); % update mergeLabel
        watershedGraph{mergeDestroyIndex} = []; % update the destroyed label
        for n = 1:length(neighborsOfDestroyed) % replace the destoyed label with the merged label in each of the destroyed neighbors lists of neighbors
            neighborIndex = labelIndex'.*(watershedLabels==neighborsOfDestroyed(n));
            neighborIndex = neighborIndex(neighborIndex~=0);
            watershedGraph{neighborIndex} = setdiff([watershedGraph{neighborIndex}, mergeLabel], mergeDestroy);
        end
       
        % update the list of closure surface areas
        closureSurfaceArea(mergeLabelIndex) = closureSurfaceAreaCombinedRegion;
        closureSurfaceArea(mergeDestroyIndex) = NaN;
       
        % remove all instances of both watersheds in the list of edges to check
        toRemove = logical( (edgesToCheck(:,1)==mergeLabel) + (edgesToCheck(:,2)==mergeLabel) + ...
            (edgesToCheck(:,1)==mergeDestroy) + (edgesToCheck(:,2)==mergeDestroy) );
        edgesToCheckFrom = edgesToCheck(:,1); edgesToCheckTo = edgesToCheck(:,2); 
        edgesToCheckFrom(toRemove) = []; edgesToCheckTo(toRemove) = [];
        edgesToCheck = [edgesToCheckFrom, edgesToCheckTo];
        
        % append a list of neighbors of the combined region to the list of edges to check
        nLabels = watershedGraph{mergeLabelIndex};
        %nLabels(nLabels<0) = 0; % !!!!!!
        toAdd = [mergeLabel.*ones(length(nLabels),1), nLabels'];
        edgesToCheck = [edgesToCheck; toAdd]; 
       
    else % remove that pair from the list of regions to check 
        edgesToCheck(1,:) = [];
    end
    
end

joinedWatersheds = watersheds;

