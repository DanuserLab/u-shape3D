function [C,CF] = connected_components(F)
  % CONNECTED_COMPONENTS Determine the connected components of a mesh described
  % by the simplex list F. Components are determined with respect to the edges of
  % the mesh. That is, a single component may contain non-manifold edges and
  % vertices.
  %
  % C = connected_components(F)
  %
  % Inputs:
  %   F  #F by simplex-size list of simplices
  % Outputs:
  %   C  #V list of ids for each CC 
  %   CF  #F list of ids for each CC
  % 
  % Examples:
  %  trisurf(F,V(:,1),V(:,2),V(:,3), ...
  %    connected_components([F;repmat(size(V,1),1,3)]));
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

  % build adjacency list
  A = adjacency_matrix(F);
  [~,C] = conncomp_gptbx(A);
  if nargout > 1 
      CF = C(F(:,1));
  end

end
