function meanEdgeLength = findMeanEdgeLength(surface)

% meanEdgeLength finds the edge length, in pixels, of a mesh given a surface (the output of the patch command)
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


% find the mean length of each face's edges
edgeLengthFaces = nan(size(surface.faces,1),1);
for v = 1:size(surface.faces,1)
    
    lengthEdge1 = sqrt(sum((surface.vertices(surface.faces(v,1),:) - surface.vertices(surface.faces(v,2),:)).^2,2));
    lengthEdge2 = sqrt(sum((surface.vertices(surface.faces(v,2),:) - surface.vertices(surface.faces(v,3),:)).^2,2));
    lengthEdge3 = sqrt(sum((surface.vertices(surface.faces(v,3),:) - surface.vertices(surface.faces(v,1),:)).^2,2));
    
    edgeLengthFaces(v) = mean([lengthEdge1 lengthEdge2 lengthEdge3]);
    
end

% find the mean edge length
meanEdgeLength = mean(edgeLengthFaces);
