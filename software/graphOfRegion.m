function [sparseRegion, nodeLabels] = graphOfRegion(neighbors,watersheds,regionLabel,varargin)

% graphOfRegion - constructs a sparse graph of a region (optionally weighted by distance)
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

% the last optional input should be edge weights
if nargin == 4
    distances = varargin{1};
end

% find a list of the faces in the region
faceIndex = 1:length(watersheds);
facesInRegion = faceIndex'.*(regionLabel==watersheds);
facesInRegion = facesInRegion(facesInRegion>0);

% make a list of edges associated with the region
fromNode = repmat(facesInRegion,3,1);
neighborsRegion = neighbors.*repmat(regionLabel==watersheds,1,3);
toNode = [neighborsRegion(neighborsRegion(:,1)>0,1); neighborsRegion(neighborsRegion(:,2)>0,2); neighborsRegion(neighborsRegion(:,3)>0,3)];

% relabel the nodes so that they have the lowest label possible 
nodeLabels = unique([facesInRegion; toNode]);
fromNodeRelabeled = zeros(length(fromNode),1);
toNodeRelabeled = zeros(length(toNode),1);
for n=1:length(nodeLabels)
    fromNodeRelabeled = fromNodeRelabeled + n.*(nodeLabels(n)==fromNode);
    toNodeRelabeled = toNodeRelabeled + n.*(nodeLabels(n)==toNode);
end

% assign edge weights
if nargin == 4
    distancesRegion = distances.*repmat(regionLabel==watersheds,1,3);
    edgeWeights = [distancesRegion(distancesRegion(:,1)>0,1); distancesRegion(distancesRegion(:,2)>0,2); distancesRegion(distancesRegion(:,3)>0,3)];
else
    edgeWeights = ones(size(toNode,1),1);
end

% make a sparse matrix of adjacent faces in the region
sparseRegion = sparse(fromNodeRelabeled, toNodeRelabeled, edgeWeights, length(nodeLabels), length(nodeLabels));
