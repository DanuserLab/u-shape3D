function onBoundary = findBoundaryFaces(watersheds, neighbors, mode)

% findBoundaryFaces - find the faces that are on the boundaries of watershed regions
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

% mode can be either 'single' or 'double.' 'double' defines double wide boundaries


% check the mode
assert(strcmp(mode,'single') || strcmp(mode, 'double'), 'The mode parameter must be either single or double');

% initialize matrices
numFaces = size(neighbors,1);
onBoundaryOnce = zeros(numFaces,1);

% iterate through the faces
for f = 1:numFaces
    
    % find the label of the current face
    fLabel = watersheds(f);
    
    % check if the face is on the boundary 
    if  fLabel > 0 && ((fLabel~=watersheds(neighbors(f,1))) || (fLabel~=watersheds(neighbors(f,2))) || (fLabel~=watersheds(neighbors(f,3))))
        onBoundaryOnce(f) = 1;
    end
    
end

% iterate through the faces again to thicken the boundary line
if strcmp(mode,'double')
    
    onBoundary = onBoundaryOnce;
    for f = 1:numFaces

        % check if the face is on the boundary
        if onBoundaryOnce(neighbors(f,1)) || onBoundaryOnce(neighbors(f,2)) || onBoundaryOnce(neighbors(f,3))
            onBoundary(f) = 1;
        end
    end
else   
    onBoundary = onBoundaryOnce;
end