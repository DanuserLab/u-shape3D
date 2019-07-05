function [surface, combinedImage, level] = threeLevelSegmentation3D(image3D, scales, nSTDsurface, insideGamma, insideBlur, insideDilateRadius, insideErodeRadius)

% threeLevelSegmentation3D combines Hunter Elliott's surface filter with an Otsu filter and an "inside" filter
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
%figure; imagesc(max(image3D(:,:,100:120), [], 3)); axis equal; axis off; colormap(gray); title('raw');

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
%figure; imagesc(max(image3Dthresh(:,:,100:120), [], 3)); axis equal; axis off; colormap(gray); title('inside'); colorbar;

% create a normalized "cell" image
foreThresh = thresholdOtsu(image3D(:));
image3D = image3D - foreThresh;
image3D = image3D/std(image3D(:));
%figure; imagesc(max(image3D(:,:,100:120), [], 3)); axis equal; axis off; colormap(gray); title('normal'); colorbar;

% create a "surface" image
q.SigmasXY = scales; q.SigmasZ = scales; q.WeightZ = 1;
maxResp = multiscaleSurfaceFilter3D(image3D,q);
surfBackMean = mean(maxResp(:));
surfBackSTD = std(maxResp(:));
surfThresh = surfBackMean + (nSTDsurface*surfBackSTD);
maxResp = maxResp - surfThresh;
maxResp = maxResp/std(maxResp(:));
%figure; imagesc(max(maxResp(:,:,100:120), [], 3)); axis equal; axis off; colormap(gray); title('maxResp'); colorbar;

% combine all three images
combinedImage = max(max(image3Dthresh, image3D), maxResp);
combinedImage = imfill(combinedImage);
combinedImage(combinedImage<0) = 0;
level = 0.999;

% remove disconnected components that might make the mesh irregular
combinedImage = removeDisconectedComponents(combinedImage, level);
%figure; imagesc(max(combinedImage(:,:,100:120), [], 3)); axis equal; axis off; colormap(gray); title('combined'); colorbar;

% generate a surface
surface = isosurface(combinedImage, level);

