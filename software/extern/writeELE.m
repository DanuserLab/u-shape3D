function writeELE(filename,E,varargin)
  % WRITEELE Write mesh elements to a .ele file
  %
  % writeELE(filename,E)
  % writeELE(filename,E,'ParameterName',ParameterValue)
  %
  % Inputs:
  %  filename  name of output file
  %  E  list of elements
  %  Optional:
  %    'MinIndex' followed by minimum index {1} (You should remember to
  %    actually change E to have that minimum index)
  %
  % Copyright 2011, Alec Jacobson (jacobson@inf.ethz.ch)
  %
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

  % default parameters
  min_index = 1;

  ii = 1;
  while ii <= numel(varargin)
    switch varargin{ii}
    case 'MinIndex'
      assert((ii+1)<=numel(varargin));
      ii = ii + 1;
      min_index = varargin{ii};
    otherwise
      error('Unsupported parameter: %s',varargin{ii});
    end
    ii = ii+1;
  end

  if min(E(:)) < min_index
    % should never be OK but let it write anyway
    warning(sprintf('Min(E) = %d < min_index (%d)',min(E(:)),min_index));
  else if min_index < min(E(:))
    % Could be OK because min_index might just be unreferenced
    warning(sprintf('Min(E) = %d > min_index (%d)',min(E(:)),min_index));
  end

  fp = fopen(filename,'w');
  % attributes are not supported
  % number of edges number of elements  0 0
  fprintf(fp,'%d %d 0\n',size(E));
  % .node is 1-indexed
  indices = (1:size(E,1)) + (min_index-1);
  % build format string
  str = '%d';
  for(ii = 1:size(E,2))
    str = [str ' %d'];
  end
  str = [str '\n'];
  fprintf(fp,str,[indices', E]');
  fclose(fp);
end
