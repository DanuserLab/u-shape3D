function positions = measureFacePositions(smoothedSurface, neighbors)

% measureFacePositions - measure the positions of mesh faces
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


% initialize variables
numFaces = size(neighbors,1);
positions = zeros(numFaces,3);

% iterate through the faces
for f = 1:numFaces
    
    % find the position of each face
    verticesFace = smoothedSurface.faces(f,:);
    positions(f,:) = (smoothedSurface.vertices(verticesFace(1),:) + smoothedSurface.vertices(verticesFace(2),:) + smoothedSurface.vertices(verticesFace(3),:))/3;
    
end