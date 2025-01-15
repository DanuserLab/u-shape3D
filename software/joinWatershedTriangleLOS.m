function [watersheds, mergeList, watershedsIntermediate] = joinWatershedTriangleLOS(mesh, triangleRatio, losRatio, raysPerCompare, neighbors, watersheds)

% joinWatershedTriangleLOS - iteratively merge regions on a 3D mesh using the triange and LOS merging rules 
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

% make a graph of adjacent local watersheds (the last input controls if flat regions are included)
[watershedLabels, watershedGraph] = makeGraphFromLabel(neighbors, watersheds, 1); 

% construct an initial list of adjacent watersheds to consider merging
edgesToCheck = [];
for w = randperm(length(watershedGraph))
   
    % find the label of the region
    wLabel = watershedLabels(w);

    % 0 indicates an unsuccessful segmentation and a negative label indicates a flat region
    if wLabel < 1, continue; end 

    % find the label of its neighbors
    nLabels = watershedGraph{w};

    % return if there are no neighbors (because perhaps it is disjoint from the rest of the structure)
    if isempty(nLabels), continue; end

    % remove 0 labels from the list of neighbors
    nLabels = nLabels(nLabels~=0);
    
    % add edges to the list of edges to check
    toAdd = [wLabel.*ones(length(nLabels),1), nLabels'];
    for c = 1:size(toAdd, 1)
        if toAdd(c,1) < toAdd(c,2)
            edgesToCheck = [edgesToCheck; toAdd(c,:)]; 
        end
    end
end

% measure the positions of the faces
numFaces = size(neighbors,1);
positions = zeros(numFaces,3);
for f = 1:numFaces
    verticesFace = mesh.faces(f,:);
    positions(f,:) = (mesh.vertices(verticesFace(1),:) + mesh.vertices(verticesFace(2),:) + mesh.vertices(verticesFace(3),:))/3;
end

% measure the size of the mesh
meshLength = max([max(positions(:,1))-min(positions(:,1)), max(positions(:,2))-min(positions(:,2)), max(positions(:,3))-min(positions(:,3))]);

% measure the closure surface area of each region
closureSurfaceArea = NaN(length(watershedLabels),1);
for w = 1:length(watershedLabels)
    if watershedLabels(w) ~= 0
        [~, closureSurfaceArea(w), ~] = closeMesh(watershedLabels(w), mesh, watersheds, neighbors);
    end
end

% calculate the patch length of the edge pairs
patchLengthSmall = zeros(size(edgesToCheck, 1), 1); 
patchLengthBig = zeros(size(edgesToCheck, 1), 1);
faceIndex = 1:length(watersheds);
for p = 1:size(edgesToCheck,1)
    [patchLengthSmall(p,1), patchLengthBig(p,1)] = calculatePatchLength(positions, watersheds, faceIndex, edgesToCheck(p,1), edgesToCheck(p,2), meshLength);
end

% measure the closure surface area of all pairs of adjacent regions found
triangleMeasure = NaN(size(edgesToCheck,1),1);
for p = 1:size(edgesToCheck,1)
    triangleMeasure(p) = calculateTriangleMeasurePair(mesh, watersheds, watershedLabels, neighbors, closureSurfaceArea, edgesToCheck(p,1), edgesToCheck(p,2), patchLengthBig(p,1), meshLength);
end
edgesToCheck(:,3) = NaN(1,length(triangleMeasure));
edgesToCheck(:,4) = triangleMeasure(:,1);
edgesToCheck(:,5) = patchLengthSmall;
edgesToCheck(:,6) = patchLengthBig;

% merge regions
numIter = 1;
mergeList = [];
while (max(edgesToCheck(:,4)) >= triangleRatio) || max(isnan(edgesToCheck(:,3))) || (max(edgesToCheck(:,3)) >= losRatio)
    
    % merge regions using the triangle rule
    edgesToCheck = sortrows(edgesToCheck, -4);
    while edgesToCheck(1,4) >= triangleRatio
        mergeList = [mergeList; edgesToCheck(1, 1:2)];
        [watersheds, watershedGraph, edgesToCheck, closureSurfaceArea] = mergeRegionPairTriangleLOS(mesh, positions, watersheds, watershedGraph, watershedLabels, neighbors, edgesToCheck, closureSurfaceArea, meshLength, raysPerCompare);
        edgesToCheck = sortrows(edgesToCheck, -4);
        disp(['triangle ', num2str(length(unique(watersheds)))])
    end
    
    % output intermediate arguments if requested
    if nargout > 1
        watershedsIntermediate.triangle{numIter} = watersheds;
    end
    
    % calculate the mutual visibility between all pairs of adjacent regions found
    if max(isnan(edgesToCheck(:,3)))
        for p = 1:size(edgesToCheck,1) 
            if isnan(edgesToCheck(p,3))
                edgesToCheck(p,3) = calculateMutualVisibilityPair(mesh, positions, watersheds, edgesToCheck(p,1), edgesToCheck(p,2), edgesToCheck(p,5), raysPerCompare, 1);
            end
        end
    end
    
    % merge regions using the line of sight rule
    edgesToCheck = sortrows(edgesToCheck, -3);
    while edgesToCheck(1,3) >= losRatio
        mergeList = [mergeList; edgesToCheck(1, 1:2)];
        [watersheds, watershedGraph, edgesToCheck, closureSurfaceArea] = mergeRegionPairTriangleLOS(mesh, positions, watersheds, watershedGraph, watershedLabels, neighbors, edgesToCheck, closureSurfaceArea, meshLength, raysPerCompare);
        edgesToCheck = sortrows(edgesToCheck, -3);
        disp(['los ', num2str(length(unique(watersheds)))])
    end
    
    % output intermediate arguments if requested
    if nargout > 1
        watershedsIntermediate.los{numIter} = watersheds;
    end
    
    numIter = numIter + 1;
end
