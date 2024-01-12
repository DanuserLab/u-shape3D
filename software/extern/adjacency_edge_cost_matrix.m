function [C] = adjacency_edge_cost_matrix(V,E)
  % ADJACENCY_EDGE_COST_MATRIX Build sparse  adjacency matrix from edge list or
  % face list
  % 
  % [C] = adjacency_edge_cost_matrix(V,E)
  % [C] = adjacency_edge_cost_matrix(V,F)
  % [C] = adjacency_edge_cost_matrix(V,T)
  %
  % Inputs:
  %  V  #V list of vertex positions
  %  E  #E by 2 edges list
  %  or 
  %  F  #F by 3 triangle list
  %  or 
  %  T  #F by 4 tet list
  % Outputs:
  %   C  #V by #V adjacency matrix weighted by edge norms
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

  if(size(E,2)>2)
    F = E;
    E = edges(F);
  end

  % compute edge norms
  edge_norms = sqrt(sum((V(E(:,1),:)-V(E(:,2),:)).^2,2));
  % number of vertices
  n = size(V,1);
  % build sparse adjacency matrix with non-zero entries indicated edge costs
  C = sparse([E(:,1);E(:,2)],[E(:,2);E(:,1)],repmat(edge_norms,[2 1]),n,n);
end
