function area = measureFaceArea(f,mesh)

% measureFaceArea - measure the area of a single face
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

% find the three vertices that compose the face
vertices = mesh.faces(f,:);

% find two vectors that describe the face
vector1 = mesh.vertices(vertices(1),:) - mesh.vertices(vertices(2),:);
vector2 = mesh.vertices(vertices(1),:) - mesh.vertices(vertices(3),:);

% measure the area of each face
area = sqrt(sum(crossProduct(vector1,vector2).^2))/2;


% a faster cross product
function z = crossProduct(x,y)
z = x;
z(:,1) = x(:,2).*y(:,3) - x(:,3).*y(:,2);
z(:,2) = x(:,3).*y(:,1) - x(:,1).*y(:,3);
z(:,3) = x(:,1).*y(:,2) - x(:,2).*y(:,1);
