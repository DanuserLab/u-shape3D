function [mutualVisibility, mutualVisibilityArray] = calculateMutualVisibilityPair(mesh, facePositions, regionLabels, firstRegionIndices, secondRegionIndices, patchLength, raysPerCompare, local)

% calculateMutualVisibilityPair - calculates the (local, if requested) mutual visibility between two patches on a mesh
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


% find the faces in each region
faceIndex = 1:size(mesh.faces,1);
firstFaces = []; secondFaces = [];
for f = 1:length(firstRegionIndices)
    firstFaces = [firstFaces, faceIndex(regionLabels == firstRegionIndices(f))];
end
for f = 1:length(secondRegionIndices)
    secondFaces = [secondFaces, faceIndex(regionLabels == secondRegionIndices(f))];
end

% just go through the whole list, and if you run out return 0
mutualVisibility = 0;

% calculate many mutual visibilities between the regions
maxPairLimitMult = max([100, length(firstFaces)/raysPerCompare, length(secondFaces)/raysPerCompare]); % this is hardcoded!!!!!
if patchLength < 10, maxPairLimitMult = 20*maxPairLimitMult; end
if local
    localSize = 2; 
else
    localSize = Inf;
end
mutualVisibilityArray = makeMutVisArray(maxPairLimitMult, localSize, mesh, firstFaces, secondFaces, patchLength, raysPerCompare);

% if the array is partially empty, try again with a larger list of tests
if ~min(isfinite(mutualVisibilityArray)) && length(firstFaces)*length(secondFaces) > maxPairLimitMult*raysPerCompare 
    disp('Using a slightly larger list of pairs')
    maxPairLimitMult = 10*maxPairLimitMult;
    mutualVisibilityArray = makeMutVisArray(maxPairLimitMult, localSize, mesh, firstFaces, secondFaces, patchLength, raysPerCompare);
end

% try again with a very large list of tests
if ~min(isfinite(mutualVisibilityArray)) && length(firstFaces)*length(secondFaces) > maxPairLimitMult*raysPerCompare 
    disp('Using a very large list of pairs')
    maxPairLimitMult = (length(firstFaces)*length(secondFaces))/(2*raysPerCompare);
    mutualVisibilityArray = makeMutVisArray(maxPairLimitMult, localSize, mesh, firstFaces, secondFaces, patchLength, raysPerCompare);
end

% if the array is again partially empty, try widening the search radius.
if ~min(isfinite(mutualVisibilityArray)) && local
    disp('increasing local size')
    localSize = 4;
    mutualVisibilityArray = makeMutVisArray(maxPairLimitMult, localSize, mesh, firstFaces, secondFaces, patchLength, raysPerCompare);
end

% not enough rays were found within the for-loop
if sum(isfinite(mutualVisibilityArray)) > raysPerCompare/3
    mutualVisibility = nanmean(mutualVisibilityArray);
else
    disp('  found too few rays to compare') % this is more problematic 
end


function mutualVisibilityList = makeMutVisArray(maxPairLimitMult, localSize, mesh, firstFaces, secondFaces, patchLength, raysPerCompare)

% if there are many, many possible rays then subsample the pairs
if length(firstFaces)*length(secondFaces) > maxPairLimitMult*raysPerCompare 
    startRay = repmat(firstFaces, 1, ceil((maxPairLimitMult*raysPerCompare)/length(firstFaces)));
    stopRay = repelem(secondFaces, ceil((maxPairLimitMult*raysPerCompare)/length(secondFaces)));
    startRay = startRay(1:min([length(startRay) length(stopRay)]));
    stopRay = stopRay(1:min([length(startRay) length(stopRay)]));
    randOrder = randperm(length(startRay));
    
% otherwise make a list of all possible pairs of rays
else
    startRay = repmat(firstFaces, 1, length(secondFaces));
    stopRay = repelem(secondFaces, length(firstFaces));
    randOrder = randperm(length(startRay));
end
pairsList = [startRay; stopRay; randOrder];
pairsList = sortrows(pairsList',3);
pairsList = pairsList(:,1:2);

% iterate through the ray intersections
mutualVisibilityList = NaN(1,raysPerCompare);
rayCount = 0;
for r = 1:size(pairsList,1)
    
    % find the position of the first face
    verticesFace = mesh.faces(pairsList(r,1),:);
    firstPosition = (mesh.vertices(verticesFace(1),:) + mesh.vertices(verticesFace(2),:) + mesh.vertices(verticesFace(3),:))/3;
    
    % find the position of the second face
    verticesFace = mesh.faces(pairsList(r,2),:);
    secondPosition = (mesh.vertices(verticesFace(1),:) + mesh.vertices(verticesFace(2),:) + mesh.vertices(verticesFace(3),:))/3;
    
    % find the direction and length of a ray from the first to the second face
    ray = secondPosition - firstPosition;
    rayLength = sqrt(sum(ray.^2));
    
    % the local line-of-sight condition
    if (rayLength > localSize*patchLength)
        continue
    end
    
    % reject rays that are too short to be reliable
    if (rayLength < 2)  
        continue
    end
    rayCount = rayCount + 1;
    ray = ray./rayLength;
    
    % add a small amount to the starting position, so that the initial ray doesn't run into the starting face mesh
    firstPosition = firstPosition + 0.5*ray;
    
    % check every face in the mesh to see if the ray and face intersect using a one-sided ray-triangle intersection algorithm
    firstMatrix = repmat([firstPosition(1) firstPosition(2) firstPosition(3)], size(mesh.faces,1), 1);
    rayMatrix = repmat([ray(1) ray(2) ray(3)], size(mesh.faces,1), 1);
    %[intersect, dist] = TriangleRayIntersectionFastOneSided(firstMatrix, rayMatrix, mesh.vertices(mesh.faces(:,2),:), mesh.vertices(mesh.faces(:,1),:), mesh.vertices(mesh.faces(:,3),:));
    [intersect, dist] = TriangleRayIntersection(firstMatrix, rayMatrix, mesh.vertices(mesh.faces(:,2),:), mesh.vertices(mesh.faces(:,1),:), mesh.vertices(mesh.faces(:,3),:), 'planeType', 'one sided');
    intersectMask = intersect & (dist > 0) & (dist <= rayLength);
    mutualVisibilityList(1,rayCount) = 1-max(intersectMask);
  
%     % iteratively merge regions until all adjacent regions have mutual visibility below the cutoff
     if rayCount == raysPerCompare
%        mutualVisibility = mean(mutualVisibilityList);
%           
%         %% debug code
%         %if rand(1) > 0.95 
%         if (mutualVisibility > 0.4) && (mutualVisibility <= 0.8)
%             %% debug code (plot the two patches with the mutual visibility displayed at the top
%             climits = [0 Inf];
%             cmap = jet(4);
% 
%             meshColor = ones(length(mesh.faces),1);
%             meshColor(firstFaces) = 2;
%             meshColor(secondFaces) = 4;
% 
%             % plot the mesh
%             figure
%             meshHandle = patch(mesh,'FaceColor','flat','EdgeColor','none','FaceAlpha',1);
% 
%             % color the mesh
%             meshHandle.FaceVertexCData = meshColor;
%             colormap(cmap);
%             caxis(climits);
% 
%             % properly set the axis
%             %axis([130 330 0 400 0 200]);
%             daspect([1 1 1]); axis off;
% 
%             % light the scene
%             %light_handle = camlight('headlight');
%             camlookat(meshHandle);
%             camlight(0,0); camlight(120,-60); camlight(240,60);
%             lighting phong;
% 
%             title(num2str(mutualVisibility))
%             1;
%        end
%        
        return
    end
    
end


% %% debug code (plot the two patches with the mutual visibility displayed at the top
% climits = [0 Inf];
% cmap = jet(4);
% 
% meshColor = ones(length(mesh.faces),1);
% meshColor(firstFaces) = 2;
% meshColor(secondFaces) = 4;
% 
% % plot the mesh
% figure
% meshHandle = patch(mesh,'FaceColor','flat','EdgeColor','none','FaceAlpha',1);
% 
% % color the mesh
% meshHandle.FaceVertexCData = meshColor;
% colormap(cmap);
% caxis(climits);
% 
% % properly set the axis
% %axis([130 330 0 400 0 200]);
% daspect([1 1 1]); axis off;
% 
% % light the scene
% %light_handle = camlight('headlight');
% camlookat(meshHandle);
% camlight(0,0); camlight(120,-60); camlight(240,60);
% lighting phong;
% 
% title(num2str(mutualVisibility))
% 
% %%  plot which faces are seen to intersest the ray
% % calculate the mean mutual visibility
% mutualVisibility = mean(mutualVisibilityList);
% 
% 
% % debug code (plot the two patches with the mutual visibility displayed at the top
% figure
% climits = [0 Inf];
% cmap = hot(4);
% 
% meshColor = ones(length(mesh.faces),1);
% meshColor(intersect) = 3;
% 
% % plot the mesh
% figure
% meshHandle = patch(mesh,'FaceColor','flat','EdgeColor','none','FaceAlpha',1);
% 
% % color the mesh
% meshHandle.FaceVertexCData = meshColor;
% colormap(cmap);
% caxis(climits);
% 
% 
% hold on % plot the intersection points
% facesToTest = faceIndex(intersect);
% for p = 1:length(facesToTest)
%     verticesFace = mesh.faces(facesToTest(p),:);
%     position = (mesh.vertices(verticesFace(1),:) + mesh.vertices(verticesFace(3),:) + mesh.vertices(verticesFace(2),:))/3;
%     plot3(position(:,1), position(:,2), position(:,3), 'LineStyle', 'none', 'Marker', '.', 'Marker', '.', 'MarkerSize', 30, 'Color', 'r');
% end
% 
% % plot the starting and end points
% plot3(firstPosition(:,1), firstPosition(:,2), firstPosition(:,3), 'LineStyle', 'none', 'Marker', '.', 'Marker', '.', 'MarkerSize', 30, 'Color', 'g');
% plot3(secondPosition(:,1), secondPosition(:,2), secondPosition(:,3), 'LineStyle', 'none', 'Marker', '.', 'Marker', '.', 'MarkerSize', 30, 'Color', 'k');
% 
% 
% % properly set the axis
% %axis([130 330 0 400 0 200]);
% daspect([1 1 1]); axis off;
% 
% % light the scene
% %light_handle = camlight('headlight');
% camlookat(meshHandle);
% camlight(0,0); camlight(120,-60); camlight(240,60);
% lighting phong;
