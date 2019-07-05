function apodizeFilter = makeApodizationFilter(OTF, maxOTF, apoHeight)

% makeApodizationFilter - creates a triangular apodization filter that decays to zero at the edge of a window defined by a height threshold approximation of the OTF
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

% calculate the image size
imageSize = size(OTF);

% smooth the OTF
smoothedOTF = filterGauss3D(OTF,3); % (the Gaussian sigma is hardcoded, but the goal of this smoothing is simply to dampen the artifacts along the axes)

% find the apodization window
ellipseWindow = smoothedOTF > (maxOTF*apoHeight); clear smoothedOTF;

% find the radius of the window in x, y, and z
radiusX = round((sum(ellipseWindow(:,ceil((imageSize(2)+1)/2),ceil((imageSize(3)+1)/2)))-1)/2);
radiusY = round((sum(ellipseWindow(ceil((imageSize(1)+1)/2),:,ceil((imageSize(3)+1)/2)))-1)/2);
radiusZ = round((sum(ellipseWindow(ceil((imageSize(1)+1)/2),ceil((imageSize(2)+1)/2),:))-1)/2);

% make a spherical apodization filter that decays linearly to the maximum radius
maxRadius = max([radiusX, radiusY, radiusZ]);
sphereFilter = zeros(max(imageSize), max(imageSize), max(imageSize));
sphereFilter(ceil((max(imageSize)+1)/2), ceil((max(imageSize)+1)/2), ceil((max(imageSize)+1)/2)) = 1;
sphereFilter = bwdist(sphereFilter);
sphereFilter = -1*(sphereFilter - maxRadius);
sphereFilter = sphereFilter./max(sphereFilter(:));
sphereFilter(sphereFilter < 0) = 0;

% stretch the filter to make it ellipsoidal
[X,Y,Z] = meshgrid(linspace(1,max(imageSize),max(imageSize)*radiusY/maxRadius), linspace(1,max(imageSize),max(imageSize)*radiusX/maxRadius), linspace(1,max(imageSize),max(imageSize)*radiusZ/maxRadius));
resizedMask = interp3(sphereFilter,X,Y,Z); clear sphereFilter X Y Z
resizedMaskSize = size(resizedMask);
enlargedResizedMask = zeros(max(imageSize), max(imageSize), max(imageSize)); 
originEnlarged = ceil((max(imageSize)+1)/2);
enlargedResizedMask((originEnlarged-ceil((resizedMaskSize(1)-1)/2)):(originEnlarged+floor((resizedMaskSize(1)-1)/2)),...
    (originEnlarged-ceil((resizedMaskSize(2)-1)/2)):(originEnlarged+floor((resizedMaskSize(2)-1)/2)),...
    (originEnlarged-ceil((resizedMaskSize(3)-1)/2)):(originEnlarged+floor((resizedMaskSize(3)-1)/2))) = resizedMask; clear resizedMask;
apodizeFilter = enlargedResizedMask((originEnlarged-ceil((imageSize(1)-1)/2)):(originEnlarged+floor((imageSize(1)-1)/2)),...
    (originEnlarged-ceil((imageSize(2)-1)/2)):(originEnlarged+floor((imageSize(2)-1)/2)),...
    (originEnlarged-ceil((imageSize(3)-1)/2)):(originEnlarged+floor((imageSize(3)-1)/2))); clear enlargedResizedMask

% normalize the apodization filter
apodizeFilter = apodizeFilter./max(apodizeFilter(:));

% % Debug figures
% figure
% imagesc(apodizeMask(:,:,1+ceil((imageSize(3)+1)/2)))
% axis equal
% 
% figure
% imagesc(log(OTF(:,:,1+ceil((imageSize(3)+1)/2))))
% axis equal
% 
% figure
% imagesc(squeeze(apodizeMask(:,1+ceil((imageSize(2)+1)/2),:)))
% axis equal
% 
% figure
% imagesc(squeeze(log(OTF(:,1+ceil((imageSize(2)+1)/2),:))))
% axis equal