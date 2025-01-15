function dataOnMesh = smoothDataOnMesh(surface, neighbors, dataOnMesh, numIter)

% smoothDataOnMesh - Perform a simple iterative smoothing of data defined on the mesh
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


% construct a sparse matrix of the faces graph
sparseMesh = faceNeighbors2sparse(surface, neighbors);

% connect each node on the mesh to itself
numNodes = size(sparseMesh,1);
sparseMesh = sparseMesh + speye(numNodes);
normalization = spdiags(full(sum(sparseMesh,2).^(-1)), 0, numNodes, numNodes);
sparseMesh = normalization*sparseMesh;

% repeatedly smooth
for k=1:numIter
    dataOnMesh = sparseMesh*dataOnMesh;
end