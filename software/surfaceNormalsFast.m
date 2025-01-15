function [faceN,vertN] = surfaceNormalsFast(S,normalize)
% SurfaceNormalsFast calculates normal vectors for the input 3D surface mesh
% 
% [faceN,vertexN] = surfaceNormalsFast(surface)
% 
% [faceN,vertexN] = surfaceNormalsFast(surface,normalze)
% 
% This function calculates a normal vector for each face and vertex in the
% input triangular mesh surface. The vertex normals are calcualted as the
% normalized vector sum of the normals of all of the adjacent faces. This
% means that it is effectively a weighted average of the normals of the
% adjacent faces. By "weighted" it is meant that larger faces will
% contribute more to the adjacent vertex normals.
%
% NOTE: If the surface mesh was generated from a 3D matrix using
% isosurface.m, then it is best to use isonormals.m to get the vertex
% normals, as these will be based on interpolation of the actual volume
% data. However, isonormals returns vertex normals only, so this function
% may still be of some use.
% 
% 
% Input:
% 
%   surface - The surface to calculate curvature on, using the FV format
%   (Faces/vertices) used by patch, isosurface etc...
% 
%   normalize - True/False. If true, the vectors will be normalized to unit
%   length. If False, the length of the normals will be proportional to the
%   area of the face (face normals), or adjacent faces (vertex normals).
%   Optional. Default is false.
%
% Output:
%
%   faceN - A Mx3 matrix containing the x,y,z components of the normal
%   vector of each face, where M is the number of faces.
%
%   vertexN - A Nx3 matrix containing the x,y,z components of the normal
%   vector of each vertex, where N is the number of vertices.
%
% Hunter Elliott
% 4/2011
%
% Meghan Driscoll
% 10/2014
% Updated to use a faster cross product
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

if nargin < 1 || isempty(S) || ~isfield(S,'vertices') || ~isfield(S,'faces')
    error('you must input a surface must be a structure using the FV format, with a field named vertices and a field named faces!')
end

if nargin < 2 || isempty(normalize)
    normalize = false;
end

%Number of faces
nTri = size(S.faces,1);

if nargout > 1
    %Number of vertices
    nVert = size(S.vertices,1);
end

% ------ Calculate the Face Normals -------- %

faceN = zeros(nTri,3);

for j = 1:nTri
    
   %Get vertices of this face
   X = S.vertices(S.faces(j,:),:);
   
   %Face normal is the cross of two sides.
   faceN(j,:) = -crossProduct(X(1,:)-X(2,:),X(2,:)-X(3,:));
      
    
end

% ----- If requested, calculate the vertex normals ----- %

if nargout > 1
    
    vertN = zeros(nVert,3);
    
    for j = 1:nVert
        
        %Average the normals of faces adjacent to this vertex        
        vertN(j,:) = mean(faceN(any(S.faces == j,2),:));  % this is the slow line      
                
    end
    if normalize
        %Normalize the vertex normals
        vertN = vertN ./ repmat(sqrt(dot(vertN,vertN,2)),1,3);
    end
end

if normalize
    %Normalize the face normals
    faceN = faceN ./ repmat(sqrt(dot(faceN,faceN,2)),1,3);
end


% a faster cross product
function z = crossProduct(x,y)
z = x;
z(:,1) = x(:,2).*y(:,3) - x(:,3).*y(:,2);
z(:,2) = x(:,3).*y(:,1) - x(:,1).*y(:,3);
z(:,3) = x(:,1).*y(:,2) - x(:,2).*y(:,1);
