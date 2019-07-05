function medianFiltered = medianFilterKD(surface, measure, radius)

% medianFilterKD - Median filter the mesh in real 3-D space
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


% get the face center positions 
nFaces = size(surface.faces,1);
faceCenters = zeros(nFaces,3);
for f = 1:nFaces
    faceCenters(f,:) = mean(surface.vertices(surface.faces(f,:),:),1);
end

% find points within the averaging radius of each surface face
iClosest = KDTreeBallQuery(faceCenters,faceCenters,radius);

% median filter the data
medianFiltered = zeros(nFaces,1);
for j = 1:numel(iClosest)
    medianFiltered(j,1) = median(measure(iClosest{j}));
end