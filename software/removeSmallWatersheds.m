function watersheds = removeSmallWatersheds(minSize, watersheds)

% removeSmallWatersheds - remove small watersheds (minSize is measured in faces)
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

% find a list of watersheds regions
regions = unique(watersheds);
regions = regions(regions>0);

% remove small regions
for r = regions'
    
    % find the number of faces in the region
    numFacesRegion = sum(watersheds==r);
    
    % if the number of faces is below minSize, remove it
    if numFacesRegion < minSize
        watersheds(watersheds==r) = 0;
    end
    
end