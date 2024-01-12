function meanFacesDistance = measureMeanFaceDistance(facePositions, neighbors)

% meanFacesDistance - find the mean distance between adjacent faces
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

distances = zeros(size(neighbors));
for f = 1:length(facePositions)
    
    % calculate the distance between each face and its three neighbors
    for x = 1:3
        distances(f,x) = sqrt(sum((facePositions(f,:) - facePositions(neighbors(f,x),:)).^2,2));
    end

end

% find the mean distance
meanFacesDistance = mean(distances(:));