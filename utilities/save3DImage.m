function save3DImage(image3D, imagePath)

% saveImage3D - saves a 3D image as a single tif (assumes that the image is already of the correct class)
%
% INPUTS:
%
% image3D - the image, which should be of the correct class already
%
% imagePath - the path and name of the image
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
assert(isnumeric(image3D), 'image3D must be a numerical matrix');
assert(ischar(imagePath), 'imagePath should be a path to an image');

% saves the first slice and overwrites any existing image of the same name
imwrite(squeeze(image3D(:,:,1)), imagePath, 'Compression', 'none')

% saves subsequent slices
imageSize = size(image3D);
for z=2:imageSize(3)
    imwrite(squeeze(image3D(:,:,z)), imagePath, 'Compression', 'none', 'WriteMode', 'append')
end