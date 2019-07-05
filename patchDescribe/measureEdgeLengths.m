function [positions, distances] = measureEdgeLengths(smoothedSurface, neighbors)

% measureEdgeLengths - measure the position of faces and the Euclidean distance between adjacent faces
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


% initialize variables
numFaces = size(neighbors,1);
%positions = zeros(numFaces,3);
distances = zeros(numFaces,3);

% measure the positions of mesh faces
positions = measureFacePositions(smoothedSurface, neighbors);
 
% % iterate through the faces twice
% for f = 1:numFaces
%     
%     % find the position of each face
%     verticesFace = smoothedSurface.faces(f,:);
%     positions(f,:) = (smoothedSurface.vertices(verticesFace(1),:) + smoothedSurface.vertices(verticesFace(2),:) + smoothedSurface.vertices(verticesFace(3),:))/3;
%     
% end

% find the distances between each face and each of its three neighbors
for f = 1:numFaces %iterate through the faces
    
    for n=1:3 % iterate thhrough the neighbors
        distances(f,n) = sum((positions(f,:) - positions(neighbors(f,n),:)).^2);
    end

end
