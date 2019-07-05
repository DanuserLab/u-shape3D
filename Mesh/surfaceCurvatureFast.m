function [K,H] = surfaceCurvatureFast(S,N)
% SurfaceCurvatureFast calculates the local curvature of each face in the input triangular mesh 
% 
% K = surfaceCurvatureFast(surface,normals)
% 
% [K,H] = surfaceCurvatureFast(surface,normals)
%
% This function will calculate an approximate curvature value for each face
% in the input triangular mesh. The surface should follow the format used
% by patch, where the surface is contained in a structure with the fields
% "faces" and "vertices"
% 
% Input: 
% 
%   surface - The surface to calculate curvature on, using the FV format
%   (Faces/vertices) used by patch, isosurface etc.
% 
%   normals - The normals of the surface at each vertex. These normals need
%   not be of unit length.
% 
%   Example:
%   To calculate the local curvature of an isosurface of an image, use the
%   following commands:
% 
%       s = isosurface(image,isoValue);
%
%       n = isonormals(image,s.vertices); 
% 
%       c = surfaceCurvature(s,n);
% 
%   Which can then be visualized with the command:
% 
%       patch(s,'FaceColor','flat','EdgeColor','none','FaceVertexCData',c)    
% 
% 
% Output:
% 
%   K = An Mx1 vector, where M is the number of faces, of the approximate
%   gaussian curvature at each face.
% 
%   H = An Mx1 vector, where M is the number of faces, of the approximate
%   mean curvature at each face.
% 
%
% References:
%
% [1] Theisel et al, "Normal Based Estimation of the Curvature Tensor for
% Triangular Meshes", Proceeeding of the Computer Graphics and
% Applications, 12th pacific Conference (PG '04)
% 
%Hunter Elliott 
%3/2010
%
%
% Meghan Driscoll
% 10/2014
% Updated to use a faster cross product
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

if nargin < 2 || isempty(S) || isempty(N)
    error('Must input surface mesh and surface normals!')
end

if ~isfield(S,'vertices') || ~isfield(S,'faces')
    error('The input surface must be a structure using the FV format, with a field named vertices and a field named faces!')
end

% number of faces
nTri = size(S.faces,1);

% barycentric coordinates for location of interpolated normal
abc = ones(1,3) * 1/3; % this will estimate curvature at the barycenter of each face.

% init array for curvature values
K = zeros(nTri,1);
H = zeros(nTri,1);

% should probably vectorize/arrayfun this at some point...
for i = 1:nTri
    
    % get the coordinates of this triangle's vertices
    X = S.vertices(S.faces(i,:),:);
    
    % get the normal vectors for these vertices
    n = N(S.faces(i,:),:);
    
    % interpolated normal
    ni = abc * n;
    
    % triangle normal
    m = crossProduct(X(2,:)-X(1,:),X(3,:)-X(2,:));
    
    % gaussian curvature - formula (12) in ref [1]
    K(i) = det(n) / (dot(ni,ni)*dot(ni,m));
    
           
    % h from formula (13) in ref [1]
    h = crossProduct(n(1,:),X(3,:)-X(2,:))+...
        crossProduct(n(2,:),X(1,:)-X(3,:))+...
        crossProduct(n(3,:),X(2,:)-X(1,:));
    
    % mean curvature - formula 
    H(i) = .5*dot(ni,h) / (sqrt(dot(ni,ni))*dot(ni,m));
              
end

% a faster cross product
function z = crossProduct(x,y)
z = x;
z(:,1) = x(:,2).*y(:,3) - x(:,3).*y(:,2);
z(:,2) = x(:,3).*y(:,1) - x(:,1).*y(:,3);
z(:,3) = x(:,1).*y(:,2) - x(:,2).*y(:,1);

% % a faster dot product
% function z = dot3D(x,y)
% z=x;
% z(1)=x(1)*y(1);
% z(2)=x(2)*y(2);
% z(3)=x(3)*y(3);

