function [surface, image3D, level] = combineImagesMeshOtsu(image3D_1, method_1, image3D_2, method_2, scaleLevel)

% combineImagesMeshOtsu - average two 3D images, each normalized by its Otsu threshold, and create a single mesh
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

% check inputs
assert(strcmp(method_1, 'Otsu') | (isscalar(method_1) && method_1>=0), 'method_1 must be set to either "Otsu" or a positive number');
assert(strcmp(method_2, 'Otsu') | (isscalar(method_2) && method_2>=0), 'method_2 must be set to either "Otsu" or a positive number');

% scale the first image by its Otsu threshold
if strcmp(method_1, 'Otsu')
    [image3D_1, level] = prepareCellOtsuSeg(image3D_1);
    level = scaleLevel*level;
    image3D_1 = image3D_1-level;
    image3D_1 = image3D_1/std(image3D_1(:));
else
    level = scaleLevel*method_1;
    image3D_1 = image3D_1-level;
    image3D_1 = image3D_1/std(image3D_1(:));
end

% scale the second image by its Otsu threshold
if strcmp(method_2, 'Otsu')
    [image3D_2, level] = prepareCellOtsuSeg(image3D_2);
    level = scaleLevel*level;
    image3D_2 = image3D_2-level;
    image3D_2 = image3D_2/std(image3D_2(:));
else
    level = scaleLevel*method_2;
    image3D_2 = image3D_2-level;
    image3D_2 = image3D_2/std(image3D_2(:));
end

% combine the two images
image3D = max(image3D_1, image3D_2);
image3D = imfill(image3D);

% remove disconnected components that might make the mesh irregular
image3D = removeDisconectedComponents(image3D, 1);

% add a black border to the image in case the cell touches the border
image3D = addBlackBorder(image3D, 1);

% create a mesh
surface = isosurface(image3D, 1);