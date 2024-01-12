function [closeCenter, closureSurfaceArea, closedMesh, closeRadius] = closeMesh(wLabel, smoothedSurface, watersheds, neighbors)

% closeMesh - close the mesh representing the region to measure its volume
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


% find the labels of the faces in the region
faceIndex = 1:length(watersheds);
facesInRegion = faceIndex'.*(wLabel==watersheds);
facesInRegion = facesInRegion(facesInRegion>0);

% make an edge list of edges associated with the region
neighborsRegion = neighbors.*repmat(wLabel==watersheds,1,3);
edgeList = [facesInRegion, neighborsRegion(neighborsRegion(:,1)>0,1); facesInRegion, neighborsRegion(neighborsRegion(:,2)>0,2); facesInRegion, neighborsRegion(neighborsRegion(:,3)>0,3)];

% find a list of the neighboring faces
facesAllNeighbors = setdiff(edgeList(:,2), facesInRegion);

% find the edges that connect the regions to its neighors
boundaryEdgesMask = ismembc(edgeList(:,2),facesAllNeighbors);
boundaryEdgeList = [edgeList(boundaryEdgesMask>0,1), edgeList(boundaryEdgesMask>0,2)];

% find the vertices that correspond to each boundary edge
vertexPairs = zeros(size(boundaryEdgeList,1),2);
for b = 1:size(boundaryEdgeList,1)
    vertexPairs(b,:) = intersect(smoothedSurface.faces(boundaryEdgeList(b,1),:), smoothedSurface.faces(boundaryEdgeList(b,2),:), 'stable'); 
    
    % maintain the order of the vertices in the pair so that the vertex directionality convention for normality will be preserved during closure
    if vertexPairs(b,1) == smoothedSurface.faces(boundaryEdgeList(b,1),1) && vertexPairs(b,2) == smoothedSurface.faces(boundaryEdgeList(b,1),3)
        vertexPairs(b,:) = fliplr(vertexPairs(b,:));
    end
end

% find the center of mass of the vertices
nVertices = vertexPairs(:,1);
closeCenter = mean([smoothedSurface.vertices(nVertices,1), smoothedSurface.vertices(nVertices,2), smoothedSurface.vertices(nVertices,3)], 1);

% find the average distance from each edge vertex to the closeCenter
closeRadius = mean(sqrt(sum((smoothedSurface.vertices(nVertices,:) - repmat(closeCenter, size(smoothedSurface.vertices(nVertices,:),1), 1)).^2, 2)));

% make a fv (faces-vertices) structure for the region  (note that the vertices are not relabeled and so the structure is large)
closedMesh.faces = [smoothedSurface.faces(facesInRegion,1), smoothedSurface.faces(facesInRegion,2), smoothedSurface.faces(facesInRegion,3)];
closedMesh.vertices = smoothedSurface.vertices;

% find a unique label for the new vertex
closeCenterLabel = size(closedMesh.vertices,1)+1;

% append the new vertex to the list of vertices
closedMesh.vertices(closeCenterLabel,:) = closeCenter;

% swap the order of the vertices in the pairs to maintain the directionality of the surface normal
vertexPairs = fliplr(vertexPairs);

% append the new faces to the list of faces 
newFaces = [vertexPairs, closeCenterLabel.*ones(size(vertexPairs,1),1)];
closedMesh.faces = [closedMesh.faces; newFaces];

% measure the closure surface area
closureMesh.vertices = closedMesh.vertices;
closureMesh.faces = newFaces;
closureSurfaceArea = sum(measureAllFaceAreas(closureMesh));

% % if the closeCenter is not defined, set it to be the middle of the object
% if isnan(closeCenter(1))
%    nVertices = smoothedSurface.faces(facesInRegion(:,1));
%    closeCenter = mean([smoothedSurface.vertices(nVertices,1), smoothedSurface.vertices(nVertices,2), smoothedSurface.vertices(nVertices,3)], 1); 
% end

% % Debug code
% figure
% patch(closedMesh)
