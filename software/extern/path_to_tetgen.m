function s = path_to_tetgen()
  % PATH_TO_TETGEN Returns absolute, system-dependent path to tetgen executable
  %
  % Outputs:
  %   s  path to tetgen as string
  %  
  % See also: tetgen
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

  if ispc
    warning([ ...
      'Dear Ladislav, is there a standard place to put executables on a pc?' ...
      'Could you put tetgen there and change this accordingly?' ...
      'Thanks, Alec']);
    s = 'c:/prg/lib/tetgen/Release/tetgen.exe';
  elseif ismac || isunix
    % I guess this means linux
    [~,s] = system('which tetgen');
    s = strtrim(s);
    if isempty(s)
      guesses = { ...
        '/usr/local/bin/tetgen', ...
        '/opt/local/bin/tetgen', ...
        '/usr/local/igl/libigl/external/tetgen/tetgen', ...
        [path_to_libigl '/external/tetgen/tetgen'], ...
        '/usr/local/libigl/external/tetgen/tetgen'};
      s = find_first_path(guesses);
    end
  end
end
