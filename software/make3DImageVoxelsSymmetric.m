function image = make3DImageVoxelsSymmetric(image,pixXY,pixZ)
%MAKE3DIMAGEVOXELSSYMMETRIC scales the input 3D image so that the voxels are symmetric 
% 
% image = make3DImageVoxelsSymmetric(image,pixXY,pixZ)
% 
% This function scales the input 3D image matrix so that the resulting
% voxels are symmetric, allowing pixel-level calculations (e.g. distance
% transform) to be calculated correctly. By symmetric it is meant that the
% physical dimensions of the voxels in each dimension. This is done based
% on the input pixel sizes in X-Y and Z. It is assumed that the last
% dimension of the matrix is the Z axis, and that the pixel sizes in the X
% and Y directions are equal. The scaling is done in the Z-direction, so
% that the resulting matrix is the same size in the first two dimensions,
% but larger in the third dimension.
%   This function is intended to be used to pre-process 3D image data where
% the spacing between z-planes is not equal to the pixel size in X-Y. The
% units of the input pixel sizes are unimportant, as only the relative
% sizes are used in scaling.
%
% Input:
% 
%   image - 3D image matrix.
% 
%   pixXY - Positive scalar specifying the size of the pixels in the X-Y
%   plane (dimensions 1,2)
% 
%   pixZ - Positive scalar specifying the size of the pixels in the z
%   direction (dimension 3)
% 
% 
% Output:
%
%   image - 3D matrix containing symmetric voxels, whose sizes in the x,y
%   and z directions are all equal to the input pixel size in the x-y
%   direction, pixXY.
%
% Hunter Elliott
% 4/2011
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

if nargin < 3 || isempty(image) || isempty(pixXY) || isempty(pixZ)
    error('You must input an image, an x-y pixel size and a z-pixel size!')
end

if ndims(image) ~=3
    error('Input image must be 3-dimensional!')
end

if any([pixXY pixZ]) <= 0 || numel(pixXY)>1 || numel(pixZ)>1
    error('The input pixel sizes must be positive scalars!');
end

%Get the image class
ogClass = class(image);
%Always do interpolation as double. interp3 doesnt support uint classes.
image = double(image);


%Factor to scale z dimension by.
scFact = pixZ/pixXY;


%Set up the interpolation points
[M,N,P] = size(image);
%[X,Y,Z] = meshgrid(1:N,1:M,1:P);
[Xi,Yi,Zi] = meshgrid(1:N,1:M,linspace(1,P,P*scFact));

%Interpolate the image.
%image = interp3(X,Y,Z,image,Xi,Yi,Zi);
image = interp3(image,Xi,Yi,Zi);

if ~strcmp(ogClass,'logical')    
    %Restore the original class if it has changed
    if ~strcmp(ogClass,'double')
        image = cast(image,ogClass);
    end
else
    %Special case for logical - a cast to logical is equivalent to
    %ceil(image), whereas we want round(image)
    image = image >= .5;
    
end
