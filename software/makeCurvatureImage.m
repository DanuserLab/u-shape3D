function curvatureImage = makeCurvatureImage(imageSize, surface, curvature, neighbors)

% makeCurvatureImage - generates an image where each pixel is the average curvature of the faces at that location
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

% initialize variables for the curvature image and number of faces in each frame
curvatureImage = nan(imageSize);
curvatureCount = zeros(imageSize);

% calculate the positions of the faces
facePositions = measureFacePositions(surface, neighbors);

% iterate through the faces
for f = 1:length(facePositions)
    
    % find what pixel the face occupies
    pixelLocation = floor(facePositions(f,:));
    
    % update the number of faces at that position
    curvatureCount(pixelLocation(2), pixelLocation(1), pixelLocation(3)) = curvatureCount(pixelLocation(2), pixelLocation(1), pixelLocation(3)) + 1;
    count = curvatureCount(pixelLocation(2), pixelLocation(1), pixelLocation(3));
    
    % find the mean curvature so far
    if count == 1
        curvatureImage(pixelLocation(2), pixelLocation(1), pixelLocation(3)) = curvature(f);
    else
        curvatureImage(pixelLocation(2), pixelLocation(1), pixelLocation(3)) = ((count-1)*curvatureImage(pixelLocation(2), pixelLocation(1), pixelLocation(3)) + curvature(f))/count;
    end
    
end