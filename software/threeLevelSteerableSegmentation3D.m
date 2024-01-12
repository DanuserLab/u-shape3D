function [surface, combinedImage, level] = threeLevelSteerableSegmentation3D(image3D, image3DnotApodized, steerableType, scales, insideGamma, insideBlur, insideDilateRadius, insideErodeRadius)

% threeLevelSteerableSegmentation3D - combines a steerable filter of a non_Apodized image with an Otsu filter and an "inside" filter of apodized images
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


%figure; imagesc(max(image3D(:,:,300:350), [], 3)); axis equal; axis off; colormap(gray); title('raw'); colorbar;

% create an "inside" image from the apodized image
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
%figure; imagesc(max(image3Dthresh(:,:,300:350), [], 3)); axis equal; axis off; colormap(gray); title('inside'); colorbar;

% create a steerable filtered image from the non-apodized image
[steerableResponse, ~, ~, ~] = multiscaleSteerableFilter3D(image3DnotApodized.^insideGamma, steerableType, scales);
levelSteer = mean(steerableResponse(:)) + 3*std(steerableResponse(:)); % 6
%figure; imagesc(max(steerableResponse(:,:,300:350), [], 3)); axis equal; axis off; colormap(gray); title('steer'); colorbar;

% combine the three images
[surface, combinedImage, level] = combineThreeImagesMeshOtsu(image3D, 'Otsu', image3Dthresh, 'Otsu', steerableResponse, levelSteer, 1);
%figure; imagesc(max(combinedImage(:,:,300:350), [], 3)); axis equal; axis off; colormap(gray); title('combine'); colorbar;
%1;
