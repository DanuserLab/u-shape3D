function [sphereVariation, sizeWatershed] = measureSpherelike(positions, watersheds, watershedLabels, measure)

% measureSpherelike - measure how spherelike each watershed region is
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

% Finds the mean position of the faces in each watershed, the average
% distance from that mean position, and the standard deviation of the 
% distance from the mean position.  Then, calculates as a measure of
% deviation from a sphere, the ratio of the standard deviation over the
% mean.

% for each watershed, measure how sphere-like it is
sphereVariation = zeros(1,length(watershedLabels));
stdDistance = zeros(1,length(watershedLabels));
meanDistance = zeros(1,length(watershedLabels));
sizeWatershed = zeros(1,length(watershedLabels));
for w = 1:length(watershedLabels)
    
    if watershedLabels(w)>0 % 0 indicates a flat-region
        
        % make a mask of faces whose measure is below zero
        measureMask = measure<0;
       
        % find the the positions of the faces in the region
        positionsRegionMask = positions.*repmat(watershedLabels(w)==watersheds,1,3).*repmat(measureMask,1,3);
        positionsRegion = [positionsRegionMask(positionsRegionMask(:,1)>0,1), positionsRegionMask(positionsRegionMask(:,2)>0,2), positionsRegionMask(positionsRegionMask(:,3)>0,3)];
        
        % if there are not positions in the region with positive measure, use the entirety of the measure
        if isempty(positionsRegion)
            positionsRegionMask = positions.*repmat(watershedLabels(w)==watersheds,1,3);
            positionsRegion = [positionsRegionMask(positionsRegionMask(:,1)>0,1), positionsRegionMask(positionsRegionMask(:,2)>0,2), positionsRegionMask(positionsRegionMask(:,3)>0,3)];
        end
        
        % find the mean positions of the faces in the region
        meanPosition = mean(positionsRegion);
        
        % calculate how much the watershed deviates from a sphere
        distances = sum((positionsRegion-repmat(meanPosition,size(positionsRegion,1),1)).^2,2);
        stdDistance(1,w) = std(distances);
        meanDistance(1,w) = mean(distances);
        sphereVariation(1,w) = stdDistance(1,w)/meanDistance(1,w);
        
        % find the number of faces in the watershed (it would be better to measure the actual size of the watersheds!!!)
        sizeWatershed(1,w) = length(watersheds(watershedLabels(w)==watersheds));
              
    end
    
end

% debug code
% 
% figure
% hist(sphereVariation,25)
% 
% figure
% hist(stdDistance, 25)
% 
% figure
% hist(meanDistance, 25)