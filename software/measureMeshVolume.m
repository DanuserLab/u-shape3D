function volume = measureMeshVolume(mesh)

% measureMeshVolume - measure the volume of a closed mesh (where the mesh is assumed to be represented by an fv struct)
%
% The volume formula is partially from 
% Cha Zhang and Tsuhan Chen. "Efficient Feature Extraction for 2D/3D
% Objects in Mesh Representation" (2001).
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

% find the signed volume of each face in the mesh
volumeTetras = zeros(size(mesh.faces,1),1);
for f = 1:size(mesh.faces,1)
    
    % find the vertices that form the face
    vertex1 = mesh.vertices(mesh.faces(f,1),:);
    vertex2 = mesh.vertices(mesh.faces(f,2),:);
    vertex3 = mesh.vertices(mesh.faces(f,3),:);
    
    volumeTetras(f) = dot(vertex1, crossProduct(vertex2,vertex3))/6;
end

volume = abs(sum(volumeTetras));


% a faster cross product
function z = crossProduct(x,y)
z = x;
z(:,1) = x(:,2).*y(:,3) - x(:,3).*y(:,2);
z(:,2) = x(:,3).*y(:,1) - x(:,1).*y(:,3);
z(:,3) = x(:,1).*y(:,2) - x(:,2).*y(:,1);