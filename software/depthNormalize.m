function dnImage = depthNormalize(image3D, image3DMask)

% depthNormalize - normalizes each pixel by the mean intensity at that distance from the mesh
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

% (this is adapted from Hunter Elliott's code)

% calculate the distance from the mask edge
distImage = bwdist(~image3DMask);

% get all distance values
distVals = unique(distImage);
distVals(distVals==0) = [];

% initialize a depth normalized image
dnImage = zeros(size(image3D));

% normalize each possible distance from the edge by the average value at that distance
for d = 1:numel(distVals)
   
    % find all the pixels at the distance d
    pixelsAtDist = (distImage==distVals(d));
    
    % normalize those pixels
    dnImage(pixelsAtDist) = image3D(pixelsAtDist)./mean(image3D(pixelsAtDist(:)));
    %dnImage = dnImage + pixelsAtDist.*image3D./mean(image3D(pixelsAtDist));
end
