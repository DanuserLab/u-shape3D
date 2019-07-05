function perimeter = measureRegionPerimeter(surface, watersheds, neighbors, onBoundary, regionLabel)

% measureRegionPerimeter - find the perimeter of a mesh region
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

% find the faces on the boundary
facesIndex = 1:length(watersheds);
boundaryFaces = facesIndex(onBoundary == 1 & watersheds == regionLabel);

% estimate the perimeter if boundaryFaces is strangely empty (likely bug in onBoundary)
if isempty(boundaryFaces) && length(facesIndex(watersheds == regionLabel)) < 25
    perimeter = length(facesIndex(watersheds == regionLabel));
    return
elseif isempty(boundaryFaces)
    perimeter = 1;
    return
end
    

% iterate through those faces to find edges along the perimeter
edges = [];
for f = 1:length(boundaryFaces)
    
    % find the watershed labels of the neighbors
    nLabels = [watersheds(neighbors(boundaryFaces(f),1)), watersheds(neighbors(boundaryFaces(f),2)), watersheds(neighbors(boundaryFaces(f),3))];
    
    % iterate through the neighbors
    for n = 1:length(nLabels)
        
        % look for foreign neighbors
        if nLabels(n) ~= regionLabel
            
            % find shared vertices
            sharedEdge = intersect(surface.faces(neighbors(boundaryFaces(f),n),:), surface.faces(boundaryFaces(f),:));
            edges = [edges; sharedEdge];
        end
    end      
    
end

% find the length of each edge
edgeLength = sqrt(sum((surface.vertices(edges(:,1),:) - surface.vertices(edges(:,2),:)).^2, 2));

% find the perimeter
perimeter = sum(edgeLength);



% 
% % make a list of edges surrounding the boundary faces
% edges = [surface.faces(boundaryFaces, 1), surface.faces(boundaryFaces, 2)]; 
% edges = [edges; surface.faces(boundaryFaces, 2), surface.faces(boundaryFaces, 3)]; 
% edges = [edges; surface.faces(boundaryFaces, 3), surface.faces(boundaryFaces, 1)]; 
% 
% % make a list of region vertices inside the boundary vertices
% innerFaces = facesIndex(onBoundary == 0 & watersheds == regionLabel);
% innerVertices = surface.faces(innerFaces, :);
% innerVertices = innerVertices(:);
% 
% % remove edges that have an inner vertex
% outerEdgesIndex = ~(ismember(edges(:,1), innerVertices) | ismember(edges(:,2), innerVertices));
% outerEdges = edges(outerEdgesIndex, :);
% 
% % find the actual length of each outer edge
% edgeLength = sqrt(sum((surface.vertices(outerEdges(:,1),:) - surface.vertices(outerEdges(:,2),:)).^2), 2);
% 
% % find the perimeter
% perimeter = sum(edgeLength);