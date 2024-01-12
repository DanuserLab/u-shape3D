function [E,A] = readELE(filename)
  % READELE Read (face or tet) elements from a .ele file, used by Stellar and
  % Triangle
  %
  % [E,A] = readELE(filename)
  % 
  % Input:
  %   filename  path to .ele file
  %
  % Output:
  %   E  list of element indices, could be triangles or tets based
  %     on header of .ele file
  %   A  #E by num_attributes list of attributes.
  %
  % Copyright 2011, Alec Jacobson (jacobson@inf.ethz.ch)
  %
  % See also readNODE
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

  ele_file_handle = fopen(filename);
  line = fscanf(ele_file_handle,' %[^\n]s');
  [header,count] = sscanf(line,'%d %d %d',3);
  % number of elements
  num_e = header(1);
  % size of an element
  size_e = header(2);
  % number of attributes
  if(count > 2)
    num_a = header(3);
  else
    num_a = 0;
  end
  %if(num_a ~= 0)
  %  error('Attributes are not supported.');
  %end

  % line always start with row index
  parser = '%d';
  num_items = 1;
  if(size_e < 1)
    error(['Size of an element must be at least one, not ' num2str(size_e)]);
  end
  % append to parser enough to read all entries in element
  parser = [parser repmat(' %d',1,size_e+num_a)];
  num_items = num_items + size_e + num_a;
  E = fscanf(ele_file_handle,parser,[num_items, num_e])';
  fclose(ele_file_handle);

  % get rid of row indices 
  offset = 1-min(min(E(:,1)),1);
  if offset
    warning('Offseting indices by %d',offset);
  end
  if isempty(E)
    A = [];
  else
    A = E(:,(1+size_e)+1:(1+size_e)+num_a);
    E = E(:,1+(1:size_e))+offset;
  end
end

