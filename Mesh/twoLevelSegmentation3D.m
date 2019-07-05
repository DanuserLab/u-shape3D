function [surface, combinedImage, level] = twoLevelSegmentation3D(image3D, insideGamma, insideBlur, insideDilateRadius, insideErodeRadius)

% twoLevelSegmentation3D combines an Otsu filter and an "inside" filter
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


% add a black border to the image in case the cell touches the border
image3D = addBlackBorder(image3D, 1);

% create an "inside" image
image3Dblurred = image3D.^insideGamma;
image3Dblurred = filterGauss3D(image3Dblurred, insideBlur);
image3DthreshValue = thresholdOtsu(image3Dblurred(:));
image3Dthresh = image3Dblurred > image3DthreshValue;
image3Dthresh = imdilate(image3Dthresh, makeSphere3D(insideDilateRadius));
for h = 1:size(image3Dthresh, 3)
    image3Dthresh(:,:,h) = imfill(image3Dthresh(:,:,h), 'holes');
end
image3Dthresh = double(imerode(image3Dthresh, makeSphere3D(insideErodeRadius)));
image3Dthresh = filterGauss3D(image3Dthresh, 1);

% create a normalized "cell" image
foreThresh = thresholdOtsu(image3D(:));
image3D = image3D - foreThresh;
image3D = image3D/std(image3D(:));

% combine both images
combinedImage = max(image3Dthresh, image3D);
combinedImage = imfill(combinedImage);
combinedImage(combinedImage<0) = 0;
level = 0.999;

% remove disconnected components that might make the mesh irregular
combinedImage = removeDisconectedComponents(combinedImage, level);

% generate a surface
surface = isosurface(combinedImage, level);

