function boundaryDist = findDistToRegionEdge(watershed, neighbors)

% findDistToReginoEdge - labels faces by the distance to the patch edge  
%
% (Note that this is not particularly great.)
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


% initialize matrices
numFaces = size(neighbors,1);
boundaryDist = inf(numFaces,1);

% make an initial matrix of faces on boundaries
for f = 1:numFaces
    
    % find the label of the current face
    fLabel = watershed(f);
    
    % check if the face is on the boundary 
    if  fLabel > 0 && ((fLabel~=watershed(neighbors(f,1))) || (fLabel~=watershed(neighbors(f,2))) || (fLabel~=watershed(neighbors(f,3))))
        boundaryDist(f) = 0;
    end
    
end

% keep checking one face further away from the edge until all faces have been checked
keepChecking = 1;
while keepChecking == 1
    
    keepChecking = 0;

    % iterate through the faces
    boundaryDistLast = boundaryDist;
    for f = 1:numFaces

        % check if the face has not been checked and if it is next to an already checked region
        if ~isfinite(boundaryDistLast(f)) && ...
            (isfinite(boundaryDistLast(neighbors(f,1))) || ...
                isfinite(boundaryDistLast(neighbors(f,2))) || ...
                isfinite(boundaryDistLast(neighbors(f,3))))
            
            % set the distance to the region edge to be the minimum of its neighbors distances plus one 
            boundaryDist(f) = min([boundaryDistLast(neighbors(f,1)), boundaryDistLast(neighbors(f,2)), boundaryDistLast(neighbors(f,3))]) + 1;
            
            % check all the faces again since at least one face as changed
            keepChecking = 1;

        end

    end

end
