function [I,R,C] = in_elements(F,T)
  % IN_ELEMENTS  Check whether each facet in F truly apears as a facet of the
  % at least one of the elements in T
  %
  % [I] = in_elements(F,T)
  % [I,R,C] = in_elements(F,T)
  %
  % Inputs:
  %   F  #F by dim list of facets
  %   T  #T by dim+1 list of elements
  % Outputs:
  %   I  #F list of indicators whether facet is in element list
  %   R  #F list revealing which *first* tet
  %   C  #F list revealing where in *first* tet
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

  assert(size(F,2)+1 == size(T,2));

  switch size(F,2)
  case 2
    allF = [T(:,[2 3]);T(:,[3 1]);T(:,[1 2])];
  case 3
    allF = [T(:,[2 3 4]);T(:,[3 4 1]);T(:,[4 1 2]);T(:,[1 2 3])];
  end
  [I,LOCB] = ismember(sort(F,2),sort(allF,2),'rows');
  R = mod(LOCB-1,size(T,1))+1;
  C = floor((LOCB-1)/size(T,1))+1; 

end
