function N = readNEIGH(filename)
  % READNEIGH  Read tetrahedral neighbor information from a .neigh file (as
  % produced by tetgen)
  % 
  % N = readNEIGH(filename)
  %
  % Inputs:
  %   filename  path to .neigh file
  % Outputs:
  %   N  #simplices by #size-of-simplex neighborhood information (-1) indicates
  %     boundary. T(i,j) *should* indicate the neighbor to the jth face of the
  %     ith tet. *However* tetgen does not seem consistent. Consider
  %     post-processing with fixNEIGH.m
  %
  % See also: tt, tetgen, readNODE, readELE, fixNEIGH
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


  fp = fopen(filename);
  line = fscanf(fp,' %[^\n]s');
  [header,count] = sscanf(line,'%d %d',2);
  if count~=2
    fclose(fp);
    error('Bad header');
  end

  % number of elements
  n = header(1);
  % size of an element
  size_e = header(2);

  parser = '%d';
  % append to parser enough to read all entries in element + 1 for index
  parser = [parser repmat(' %d',1,size_e+1)];
  N = fscanf(fp,parser,[size_e+1 n])';
  fclose(fp);

  % get rid of row indices and make one indexed
  N = N(:,2:end) + 1;
  N(~N) = -1;
end


