function image3D = removeDisconectedComponents(image3D, level)

% removeDisconnectedComponents - zeros all but the largest connected component in a 3D image that is above the provided threshold
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

% threshold the image
imageThreshold = (image3D > level);

% find the number of pixels in each of the connected components
CC = bwconncomp(imageThreshold);
numPixels = cellfun(@numel,CC.PixelIdxList);

% find the label of the largest connected component
[~,label] = max(numPixels);

% zero all of the other connected components
for c = 1:length(numPixels)
    if c ~= label
        image3D(CC.PixelIdxList{c}) = 0;
    end
end

