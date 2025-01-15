function sparseMatrix = faceNeighbors2sparse(surface, neighbors)

% faceNeighbors2sparse - Converts an edge list of faces to a sparse matrix weighted by 1/distance
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

% measure the distance between adjacent faces
[~, distances] = measureEdgeLengths(surface, neighbors);

fromNode = 1:size(neighbors,1); % the edges go from these nodes
fromNode = repmat(fromNode',3,1); 
toNode = [neighbors(:,1); neighbors(:,2); neighbors(:,3)]; % the edges go to these nodes
edgeWeights = 1./[distances(:,1); distances(:,2); distances(:,3)];
%edgeWeights = ones(size(toNode,1),1);

% create the sparse matrix
sparseMatrix = sparse(fromNode, toNode, edgeWeights);
