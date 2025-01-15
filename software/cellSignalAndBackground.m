function [signalMean, signalMax, signalSTD, backgroundMean, backgroundSTD] = cellSignalAndBackground(image3D, imageBlurSize, sphereErodeSE, sphereDilateSE)

% cellSignalAndBackground - estimates the mean and standard deviation of both the signal and background by assuming an image of uniformly lit objects
%
% Blurs and then Otsu thresholds the image. Erodes the image and then sets
% the mean intensity of the eroded image to be the magnitude of the signal. 
% Dilates the thresholded image and then sets the standard deviation 
% outside the dilated region to be the noise.
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

% INPUTS:
%
% imageBlur      - the standard deviation in pixels of the gaussian that 
%                the image is blurred with prior to segmentation
%
% sphereErodeSE  - the structuring element for the erosion operation
%
% sphereDilateSE - the strcturing element for the dilation operation


% blur the image
imageBlured = filterGauss3D(image3D,imageBlurSize);
imageBlured = imageBlured-min(imageBlured(:));
imageBlured = imageBlured./max(imageBlured(:));

% threshold the image
imageThresh = imageBlured>graythresh(imageBlured(:)); %clear imageBlured; 

% fill in holes
imageThresh = imfill(imageThresh, 'holes');

% measure the mean and max signal intensity
imageErodeMask = imerode(imageThresh, sphereErodeSE); % erode the images
imageSignal = imageErodeMask.*image3D;
signalSTD = mean(imageSignal(imageErodeMask));
signalMax = max(imageSignal(imageErodeMask));
signalMean = mean(imageSignal(imageErodeMask)); %clear imageSignal imageErodeMask sphereErodeSE;

% measure the standard deviation of the background
imageDilateMask = imdilate(imageThresh, sphereDilateSE); %clear imageThresh;
imageBackground = (~imageDilateMask).*image3D; 
backgroundSTD = std(imageBackground(~imageDilateMask));
backgroundMean = mean(imageBackground(~imageDilateMask));
