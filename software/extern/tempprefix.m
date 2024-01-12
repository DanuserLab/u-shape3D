function T = tempprefix(D);
  % TEMPPREFIX returns a unique name prefix, starting with the given directory
  %   suitable for use as a prefix for temporary files.
  %
  % T = tempprefix(D)
  % T = tempprefix()  same as above but uses builtin tempdir as D
  %
  % Inputs:
  %   D  name of directory to find prefix
  % Outputs:
  %   T  unique temp prefix
  %
  % Copyright 2011, Alec Jacobson (jacobson@inf.ethz.ch)
  %
  % See also: tempname
  % 
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

  while(true)
    if(exist('D','var'))
      T = tempname(D);
    else
      T = tempname();
    end
    if(isempty(dir([T '*'])))
      break;
    end
  end
end
