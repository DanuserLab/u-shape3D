function [blebStats, cellStats] = surface2blebStatistics(stats, cellStats, blebSegment, surfaceSegment)

% surface2blebStatistics - converts the patch statistics structure to a structure specific only to blebs
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

% find lists of the surface patches and blebs
patchIndices = unique(surfaceSegment);
patchIndices = patchIndices(patchIndices > 0);
blebIndices = unique(blebSegment);
blebIndices = blebIndices(blebIndices > 0);

% initialize a blebStats variable
blebStats = stats;

% update the bleb count
cellStats.blebCount = length(blebIndices);
blebStats.count = length(blebIndices);

% make a mask of patches to keep
keepMask = ismember(patchIndices, blebIndices);

% find a list of fields of stats
names = fieldnames(stats);

% update the fields one by one
for f = 1:size(names,1)
    
    % find the value of the field
    % (yes, evals are annoying)
    field = eval(['stats.' names{f,1}]);
    
    % if the field has the wrong size, keep going
    if size(field,1) ~= length(patchIndices)
        continue;
    end
    
    % set the value of the field in blebStats
    % (another eval)
    blebField = field;
    blebField(keepMask == 0,:) = [];
    eval(['blebStats.' names{f,1} ' = blebField;']);

end
