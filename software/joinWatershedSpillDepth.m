function joinedWatersheds = joinWatershedSpillDepth(depthThreshold, neighbors, watersheds, measure, useRidgeHeights, heightDepthRatioThreshold)

% joinedNeighbors - joins watershed regions by iteratively merging the region with the lowest depth until the depth threshold is reached
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

% make a graph of adjacent local watersheds
[watershedLabels, watershedGraph] = makeGraphFromLabel(neighbors, watersheds, 0); 

% measure the depths of the watershed regions
[spillDepths, spillNeighbors, ridgeHeights] = measureDepthsAll(neighbors, watersheds, watershedLabels, watershedGraph, measure);

% iteratively merge regions until all of the regions with depths less than the threshold have been merged
% (update the various data structure at each iteration, but keep the indexing into the list at its full size)
labelIndex = 1:length(watershedLabels);
keepMerging = 1;
while keepMerging

    % find two regions to merge (merge the region with lowest depth into its spill neighbor)
    if useRidgeHeights % if the ridge height is being used as an additional condition
        thresholdMask = (spillDepths < depthThreshold).*(ridgeHeights./spillDepths > heightDepthRatioThreshold);
        [~, toMergeIndex] = max((ridgeHeights./spillDepths).*thresholdMask);
    else % if spill depth is being used as a condtion, find the smallest spill depth
        [~, toMergeIndex] = min(spillDepths);
    end
    
    toMerge = watershedLabels(toMergeIndex(1));
    toMergeInto = spillNeighbors(toMergeIndex(1));
    
    % label the new region by the minimum of the two labels
    mergeLabel = min(toMerge, toMergeInto);
    mergeDestroy = max(toMerge, toMergeInto);
    
    % find the indices of the labels in watershedGraphs
    mergeLabelIndex = labelIndex'.*(watershedLabels==mergeLabel);
    mergeLabelIndex = mergeLabelIndex(mergeLabelIndex>0);
    mergeDestroyIndex = labelIndex'.*(watershedLabels==mergeDestroy);
    mergeDestroyIndex = mergeDestroyIndex(mergeDestroyIndex>0);
    
    % update the list of watersheds indexed by face
    if mergeLabel==toMerge
        watersheds(watersheds==toMergeInto) = mergeLabel;
    else
        watersheds(watersheds==toMerge) = mergeLabel;
    end
    
    % update watershedGraph, which lists the neighbors of each region
    neighborsOfDestroyed = watershedGraph{mergeDestroyIndex}; % find the neighbors of the desroyed label
    neighborsOfDestroyed = setdiff(neighborsOfDestroyed, mergeLabel);
    watershedGraph{mergeLabelIndex} = setdiff([watershedGraph{mergeLabelIndex}, neighborsOfDestroyed], [mergeLabel, mergeDestroy]); % update mergeLabel
    watershedGraph{mergeDestroyIndex} = []; % update the destroyed label
    for n = 1:length(neighborsOfDestroyed) % replace the destoyed label with the merged label in each of the destroyed neighbors lists of neighbors
        neighborIndex = labelIndex'.*(watershedLabels==neighborsOfDestroyed(n));
        neighborIndex = neighborIndex(neighborIndex>0);
        watershedGraph{neighborIndex} = setdiff([watershedGraph{neighborIndex}, mergeLabel], mergeDestroy); 
    end
    
    % update the spillDepths and spillNeighbors  
    spillDepths(mergeDestroyIndex) = Inf;
    ridgeHeights(mergeDestroyIndex) = 0;
    spillNeighbors(mergeDestroyIndex) = 0;
    spillNeighbors(spillNeighbors==mergeDestroy) = mergeLabel;
    [spillDepths(mergeLabelIndex), spillNeighbors(mergeLabelIndex), ridgeHeights(mergeLabelIndex)] = measureDepthOneRegion(mergeLabelIndex, neighbors, watersheds, watershedLabels, watershedGraph, measure);
    
    % check if there are more regions to be merged
    keepMerging = 0;
    if useRidgeHeights % if the height to spill depth ratio is being used as a joining condition
        if max((ridgeHeights./spillDepths > heightDepthRatioThreshold).*(spillDepths < depthThreshold))
            keepMerging = 1;
        end
    
    else % if spill depth is being used as a joining condition
        if min(spillDepths) < depthThreshold
            keepMerging = 1; 
        end
    end
    
end

joinedWatersheds = watersheds;