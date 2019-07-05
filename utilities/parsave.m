function parsave(fileName,varargin)

% parsave - saves workspace variables even inside a parfor loop
% (modified from a Mathworks blog)
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

% INPUTS:
%
% filename - the path and name of the file to be saved
%
% (variables) - include the variables to be saved as subsequent inputs


% check that the first input is a string
assert(ischar(fileName), 'fileName must be a string');

% put all the variables that will be saved in one structure
for n = 2:nargin
    savevar.(inputname(n)) = varargin{n-1};
end

% save the variables
save(fileName, '-struct', 'savevar','-v7.3')