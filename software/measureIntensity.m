function faceIntensities = measureIntensity(image3D, surface, radius)

% measureIntensity - measures the image intensity near each face of a mesh
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


% find the positions of each face
numFaces = size(surface.faces,1);
facePositions = zeros(numFaces,3);
for f = 1:numFaces
    verticesFace = surface.faces(f,:);
    facePositions(f,:) = (surface.vertices(verticesFace(1),:) + surface.vertices(verticesFace(2),:) + surface.vertices(verticesFace(3),:))/3;
end

% convert the pixels to a list of coordinates with associated intensities
pixelsIndices = find(image3D > 0);
[pixelsXYZ(:,2),pixelsXYZ(:,1),pixelsXYZ(:,3)] = ind2sub(size(image3D),pixelsIndices);

% call KD-tree on each face
faceIntensities.mean = zeros(numFaces,1);
tree = kdtree_build(pixelsXYZ);
for f = 1:numFaces
    indicesRange = kdtree_ball_query(tree, facePositions(f,:), radius);
    faceIntensities.mean(f) = mean(image3D(pixelsIndices(indicesRange)));
end

%% normalize the intensities by the mean face intensity
%faceIntensities.mean = faceIntensities.mean./(mean(faceIntensities.mean));
 

% %% debug plot
% figure
% cmap = flipud(makeColormap('div_spectral', 1024));
% cmap = flipud(makeColormap('div_pwg', 1024));
% climits = [prctile(faceIntensities.mean,1), prctile(faceIntensities.mean,99)];
% %climits = [0.5, 2];
% plotMeshFigure(image3D, surface, faceIntensities.mean, cmap, climits);
