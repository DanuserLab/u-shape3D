function structCombined = combineStructures(oldStruct, newStruct)

% combineStructures - combines the fields of two structures, using newStruct to define any overlapping fields
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

% check inputs
assert(isempty(oldStruct) || isstruct(oldStruct), 'the oldStruct parameter must be empty or a structure')
assert(isempty(newStruct) || isstruct(newStruct), 'the newStruct parameter must be empty or a structure')

% combine the structure
if isempty(newStruct) % if the new structure is empty provide the old structure
    structCombined = oldStruct;
elseif isempty(oldStruct) % if the old structure is empty provide the new structure
    structCombined = newStruct;
else % combine fields
    oldStruct = rmfield(oldStruct, intersect(fieldnames(oldStruct), fieldnames(newStruct)));
    names = [fieldnames(oldStruct); fieldnames(newStruct)];
    structCombined = cell2struct([struct2cell(oldStruct); struct2cell(newStruct)], names, 1);
end
