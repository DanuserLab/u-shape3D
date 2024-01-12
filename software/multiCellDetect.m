function image3D = multiCellDetect(image3D, gaussSizePreThresh, minVolume, dilateRadius, cellIndex)

% multiCellDetect - remakes the 3D image so that only the xth most bright cell is visible (iffy)
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


% smooth the image
image3Dsmooth = filterGauss3D(image3D, gaussSizePreThresh);

% normalize the image intensity
image3Dsmooth = image3Dsmooth - min(image3Dsmooth(:));
image3Dsmooth = image3Dsmooth./max(image3Dsmooth(:));

% bin the intensities
[binCounts,binEdges] = histcounts(image3Dsmooth(:));
binCoord = (binEdges(1:end-1) + binEdges(2:end))/2;

% set the x and y "coordinates" of the corner plot
x = binCoord./max(binCoord);
y = sum(binCounts) - cumsum(binCounts); y = y./max(y);

% find the index into the corner intensity
[~, minIndex] = min(sqrt(x.^2+y.^2));

% threshold the image
threshold = binCoord(minIndex);
imageMask = (image3Dsmooth > threshold);

% remove small objects
imageMask = bwareaopen(imageMask, minVolume);

% fill holes in the image
imageMask = imfill(imageMask, 'holes');

% remove objects on the sides of the image
imageMask = imclearborder(imageMask);

% label the image
imageLabeled = bwlabeln(imageMask, 26);

% pick the nth cell by total brightness
numCells = max(imageLabeled(:));
totalBright = zeros(1,numCells);
for i = 1:numCells
    totalBright(1,i) = sum(image3D(imageLabeled == i));
end
[~,sortI] = sort(totalBright, 'descend');
imageMask = (imageLabeled == sortI(cellIndex));

% dilate the mask
sphereDilateSE = makeSphere3D(dilateRadius);
imageMask = imdilate(imageMask, sphereDilateSE);

% select only the chosen cell and subtract the minimum
image3D = image3D.*imageMask;
image3D = image3D - min(image3D(imageMask));
image3D(image3D < 0) = 0;

% find an Otsu threshold for each region
% numCells = max(imageLabeled(:));
% otsuLevels = zeros(1, numCells);
% image3Done = imfill(filterGauss3D(image3D, gaussSizeFinal));
% for i = 1:numCells
%     regionIntens = image3Done(imageLabeled == i);
%     regionIntensN = regionIntens - min(regionIntens);
%     regionIntensN = regionIntensN./max(regionIntensN);
%     otsu = graythresh(regionIntensN);
%     otsuLevels(1,i) = min(regionIntens) + (max(regionIntens) - min(regionIntens))*otsu;
% end
