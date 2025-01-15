function vertexIntensities = measureIntenistyVertex(image3D, surface, radius)
% measureIntensity - measures the image intensity near each vertex of a mesh
%
%INPUT
% image3D      3D (raw)image or imageSurface from uShape3D
% surface      triangle mesh surface with two structures: faces & vertices
% radius       a radius of a sphere for averaging the intensity around each
%              vertex (in pixels)
%OUPUT
% vertexIntensities     a vertex with mean field to emphasize we used "mean"
%                       of intensity within a sphere with a given radius on
%                       each vertex
%
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

% created by Hanieh Mazloom-Farsibaf - Danuser lab 2021
% Copyright (C) 2021, Danuser Lab - UTSouthwestern 

% convert the pixels to a list of coordinates with associated intensities
pixelsIndices = find(image3D > 0);
[pixelsXYZ(:,2),pixelsXYZ(:,1),pixelsXYZ(:,3)] = ind2sub(size(image3D),pixelsIndices);

% call KD-tree on each vertex
nv=size(surface.vertices,1);
vertexIntensities.mean = zeros(nv,1);
tree = kdtree_build(pixelsXYZ);
for v = 1:nv
    indicesRange = kdtree_ball_query(tree, surface.vertices(v,:), radius);
    vertexIntensities.mean(v) = mean(image3D(pixelsIndices(indicesRange)));
end

% normalize the intensities by the mean vertex intensity
% vertexIntensities.mean = vertexIntensities.mean./(mean(vertexIntensities.mean));
 
% %% debug plot
% figure
% cmap = flipud(makeColormap('div_spectral', 1024));
% cmap = flipud(makeColormap('div_pwg', 1024));
% climits = [prctile(faceIntensities.mean,1), prctile(faceIntensities.mean,99)];
% %climits = [0.5, 2];
% plotMeshFigure(image3D, surface, faceIntensities.mean, cmap, climits);
