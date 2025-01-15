function [faceIsFlat, faceIsMin, flowOut, flowIn] = assignGradientAtNodes(neighbors, measure)

% assignGradientAtNodes - Find the the gradient direction of the measure at every node
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


% initialize outputs
faceIsFlat = zeros(length(neighbors), 1);
faceIsMin = zeros(length(neighbors), 1);
flowOut = NaN(length(neighbors), 1);
flowIn = cell(length(neighbors), 1);
% maxFlowDif = zeros(length(neighbors), 1);

for f = 1:size(neighbors,1) % iterate through the faces
    
    % find the difference in the measure between neighbors (this is unnecessarily calculated twice for each pair of neighbors)
    measureDif(1) = measure(neighbors(f,1))-measure(f);
    measureDif(2) = measure(neighbors(f,2))-measure(f);
    measureDif(3) = measure(neighbors(f,3))-measure(f);
    
    % check if the region is flat
    if ~measureDif
        faceIsFlat(f) = true;
    
    % check if the region is a minimum (this isn't really correct)
    elseif (measureDif > 0) 
        faceIsMin(f) = true;
    
    % the region is sloped so assign gradient directions    
    else
        [~, minNeighbor] = min(measureDif);
        flowOut(f) = neighbors(f,minNeighbor);
        flowIn{flowOut(f)} = [flowIn{flowOut(f)}, f];
    end
    
    % % find the largest difference in measures
    % maxFlowDif(f) = max(measureDif)-min(measureDif);

end