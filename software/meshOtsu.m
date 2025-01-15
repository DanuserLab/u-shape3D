function [surface, image3D, level] = meshOtsu(image3D, scaleOtsu)

% meshOtsu - creates an isosurface by Otsu thresholding
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

% prepareCellOtsuSeg - calculates an Otsu threshold and prepares the image for thresholding
[image3D, level] = prepareCellOtsuSeg(image3D);

% scale the Otsu threshold
level = scaleOtsu*level;

% remove disconnected components that might make the mesh irregular 
image3D = removeDisconectedComponents(image3D, level);
%image3D = removeSmallDisconectedComponents(image3D, 150, level);

% add a black border to the image in case the cell touches the border
image3D = addBlackBorder(image3D, 1);

% create a mesh
surface = isosurface(image3D, level);