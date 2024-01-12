function sdf = calculateShapeDiameterFunctionRegion(mesh, facePositions, faceNormals, watersheds, selfRegionIndex, raysPerCompare)

% calculateShapeDiameterFunctionRegion - for a patch, calculate the shape diameter function 
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

maxAngle = pi/3; % the maximum allowed angle between the inverse normal and the random angle

% find the faces in the region
faceIndex = 1:size(mesh.faces,1); facesRegion = [];
for f = 1:length(selfRegionIndex)
    facesRegion = [facesRegion, faceIndex(watersheds == selfRegionIndex(f))];
end

% iterate through the comparisions
sdfArray = nan(1,raysPerCompare); selfVisArray = nan(1,raysPerCompare);
rayCount = 0; numLoops = 0;
while rayCount < raysPerCompare
    
    % pick a face in the region and find its position
    startFace = facesRegion(randi([1 length(facesRegion)], 1));
    startPosition = facePositions(startFace,:);
    
    % find the normal to the surface at that point
    normal = faceNormals(startFace, :);
    normal = -1*normal./sqrt(sum(normal.^2));
    if min(isfinite(normal)) == 0, continue; end
    
    % pick a random angle at which to send out a ray
    [rayX, rayY, rayZ] = sph2cart(2*pi*rand(1), 2*pi*rand(1), 1); ray = [rayX, rayY, rayZ];
    if min(isfinite(ray)) == 0, continue; end
    aCount = 0;
    while dot(normal, ray) > cos(maxAngle)
        aCount = aCount+1;
        [rayX, rayY, rayZ] = sph2cart(2*pi*rand(1), pi*rand(1), 1); ray = [rayX, rayY, rayZ];
        if aCount > 100
            error('Too many angles were calculated.')
        end
        
    end
    
    % add a small amount to the starting position, so that the initial ray doesn't run into the starting face mesh
    startPosition = startPosition + 0.5*ray;
    
    % check every face in the mesh to see if the ray and face intersect using a one-sided ray-triangle intersection algorithm
    startMatrix = repmat([startPosition(1) startPosition(2) startPosition(3)], size(mesh.faces,1), 1);
    rayMatrix = repmat([ray(1) ray(2) ray(3)], size(mesh.faces,1), 1);
    [intersect, dist] = TriangleRayIntersection(startMatrix, rayMatrix, mesh.vertices(mesh.faces(:,2),:), mesh.vertices(mesh.faces(:,1),:), mesh.vertices(mesh.faces(:,3),:), 'planeType', 'one sided');
    intersectMask = dist.*(intersect & (dist > 2)); intersectMask(intersectMask == 0) = Inf;
    [minDist, faceIntersectIndex] = min(intersectMask);
    
    % find the sdf and visibility of the ray
    if minDist < Inf
        
        % set the sdf
        sdfArray(1,rayCount+1) = minDist; 
        
%         % find the watershed label of the intersecting face
%         watershedLabel = watersheds(faceIntersectIndex);
%         if watershedLabel == selfRegionIndex
%             selfVisArray(rayCount+1) = 1;
%         else
%             selfVisArray(rayCount+1) = 0;
%         end
        
        % update the rayCount
        rayCount = rayCount + 1;
    end
    numLoops = numLoops + 1;
    
    % if the rayCount is extremely large, give up
    if numLoops > 100*raysPerCompare
        break
    end
      
end

% % calculate the self visibility
% selfVisibility = nanmean(selfVisArray);
% if isempty(selfVisibility), selfVisibility = nan; end

% calculate the shape diameter function, remove values more than one standard deviation from the median
%selfVisArray(isnan(sdfArray)) = []; 
sdfArray(isnan(sdfArray)) = []; 
sdfMedian = median(sdfArray); 
sdfSTD = std(sdfArray); 
%selfVisArray(sdfArray > sdfMedian + sdfSTD) = []; 
sdfArray(sdfArray > sdfMedian + sdfSTD) = []; 
%selfVisArray(sdfArray < sdfMedian - sdfSTD) = []; 
sdfArray(sdfArray < sdfMedian - sdfSTD) = [];
sdf = mean(sdfArray); 
%selfVisibilityCentral = mean(selfVisArray);
%if isempty(selfVisibilityCentral), selfVisibilityCentral = nan; end

% % debug code
% climits = [0 Inf];
% cmap = jet(3);
% 
% meshColor = ones(length(mesh.faces),1);
% meshColor(facesRegion) = 3;
% 
% % plot the mesh
% figure
% meshHandle = patch(mesh, 'FaceColor', 'flat', 'EdgeColor', 'none', 'FaceAlpha', 1);
% 
% % color the mesh
% meshHandle.FaceVertexCData = meshColor;
% colormap(cmap);
% caxis(climits);
% 
% % properly set the axis
% daspect([1 1 1]); axis off;
% 
% % light the scene
% camlookat(meshHandle);
% camlight(0,0); camlight(120,-60); camlight(240,60);
% lighting phong;
% 
% % add a title
% title(['sdf ' num2str(sdf) '; self vis ' num2str(selfVisibilityCentral)])
% 1
