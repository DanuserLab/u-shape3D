function image3DLarge = addBlackBorder(image3D, width)

% addBlackBorder - adds a black border of specified width to a 3D image
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
 
% find the image size
imageSize = size(image3D);

% initialize a slightly larger black image
image3DLarge = median(image3D(:))+zeros(imageSize(1)+2*width, imageSize(2)+2*width, imageSize(3)+2*width);

% set image3D to be the center of the black image
image3DLarge(width+1:end-width, width+1:end-width, width+1:end-width) = image3D;
