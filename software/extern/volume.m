function [v,sv] = volume(V,T)
  % VOLUME Compute volumes of tets T defined over vertices V
  %
  % v = volume(V,T)
  % 
  % Inputs:
  %   V  #V by dim>=3 list of vertex positions
  %   T  #T by 4 list of tetrahedra indices
  % Ouputs:
  %   v  #T list of tet volumes. Signed if dim = 3
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

  a = V(T(:,1),:);
  b = V(T(:,2),:);
  c = V(T(:,3),:);
  d = V(T(:,4),:);
  % http://en.wikipedia.org/wiki/Tetrahedron#Volume
  % volume for each tetrahedron

  % Minus sign so that typical tetgen mesh has positive volume
  %v = -dot((a-d),cross2(b-d,c-d),2)./6./4;
  % Not sure where that ./4 came from...
  v = -dot((a-d),cross2(b-d,c-d),2)./6;
  function r = cross2(a,b)
    % Optimizes r = cross(a,b,2), that is it computes cross products per row
    % Faster than cross if I know that I'm calling it correctly
    r =[a(:,2).*b(:,3)-a(:,3).*b(:,2), ...
        a(:,3).*b(:,1)-a(:,1).*b(:,3), ...
        a(:,1).*b(:,2)-a(:,2).*b(:,1)];
  end
end
