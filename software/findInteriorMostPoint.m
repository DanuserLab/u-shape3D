function [centerValue, centerLocation] = findInteriorMostPoint(image3DBinary)

% findMostInteriorPoint - given a binary 3D image of a cell, find the interior point that is farthest from the cell edge 
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

% fill the binary image
image3DBinary = imfill(image3DBinary, 'holes');

% find the distance from the cell edge
imageDist = bwdist(~image3DBinary);

% find the value and location of the interior-most point 
% (not stable if there is more than one such point)
centerValue = max(imageDist(:));
locationIndex = find(imageDist==centerValue, 1);
[iLoc, jLoc, kLoc] = ind2sub(size(imageDist), locationIndex);
centerLocation = [iLoc, jLoc, kLoc];
