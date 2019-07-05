function [labels, segmentationGraph] = makeGraphFromLabel(neighbors, labeledFaces, includeFlat)

% makeGraphFromLabel - make a graph from a spatial segmentation of faces labeled by label
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


% initialize a cell array of connections
labels = unique(labeledFaces);
labelIndex = 1:length(labels);
segmentationGraph = cell(length(labels),1);

% iterate therough all the faces to look for edges in the segmentation graph
for node = 1:size(neighbors,1)
    nodeLabel = labeledFaces(node);
    
    % check if the node should be included in the graph
    isGoodNode = 1;
    if nodeLabel == 0, isGoodNode = 0; end
    if ~includeFlat && nodeLabel<0, isGoodNode = 0; end
    
    if isGoodNode
        
        % compare the node label to each of the neighbors
        for i = 1:3
            neighborlabel = labeledFaces(neighbors(node,i)); % the face label
            
            % if the neighbor is labeled differently than the node then there is an edge
            if nodeLabel ~= neighborlabel && neighborlabel 
                
                % find the index of the label in the list of labels (this is awkward)
                arrayIndex = (labelIndex'.*(nodeLabel==labels))>0; 
                
                segmentationGraph{arrayIndex} = [segmentationGraph{arrayIndex}, neighborlabel];
            end
        end                
    end
end
       
% only list edges once in the cell array of edges
for i = 1:length(labels)
    segmentationGraph{i} = unique(segmentationGraph{i});
end