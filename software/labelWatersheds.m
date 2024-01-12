function watersheds = labelWatersheds(neighbors, measure)

% labelWatersheds - perform a watershed segmentation of measure on the mesh
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

% find the local minima and the flow direction at all faces
[~, isMin, ~, flowIn] = assignGradientAtNodes(neighbors, measure);

% initialize the watersheds matrix
watersheds = zeros(size(measure, 1), 1);

% find the watershed for each local minima (the flat regions will mess this up
faceIndex = 1:size(isMin,1);
minima = faceIndex(isMin==1);
for m = minima
    
    % label the minima
    watersheds(m) = m;
    
    % make a list of neighboring nodes that flow into this node
    nodesToExplore = flowIn{m};
    
    while ~isempty(nodesToExplore)  
        
        % examine a node
        node = nodesToExplore(1); 
        
        % label the node by the index of the minima node
        watersheds(node) = m;
        
        % update the list of nodes to explore
        nodesToExplore(1) = []; 
        nodesToExplore = [nodesToExplore, flowIn{node}];
    end
    
end