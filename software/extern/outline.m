function [O] = outline(F)
  % OUTLINE Find outline (boundary) edges of mesh
  %
  % [O] = outline(F)
  % 
  % Input:
  %  F  #F by polysize face list of indices
  % Output:
  %  O  #O by 2 list of outline edges
  %
  % Example:
  %   [V,F] = create_regular_grid(17,17,0,0);
  %   [O] = outline(F);
  %   % extract unique vertex indices on outline
  %   [u,m,n] = unique(O(:));
  %   % original map O = IM(O)
  %   IM = 1:size(V,1);
  %   IM(O(:)) = n;
  %   % list of vertex positions of outline
  %   OV = V(u,:);
  %   % list of edges in OV 
  %   OE = IM(O);
  %   tsurf(F,V);
  %   hold on;
  %   plot( ...
  %     [OV(OE(:,1),1) OV(OE(:,2),1)]', ...
  %     [OV(OE(:,1),2) OV(OE(:,2),2)]', ...
  %     '-','LineWidth',5);
  %   hold off;
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

  %%
  %% This does not maintain original order
  %%
  %% Find all edges in mesh, note internal edges are repeated
  %E = sort([F(:,1) F(:,2); F(:,2) F(:,3); F(:,3) F(:,1)]')';
  %% determine uniqueness of edges
  %[u,m,n] = unique(E,'rows');
  %% determine counts for each unique edge
  %counts = accumarray(n(:), 1);
  %% extract edges that only occurred once
  %O = u(counts==1,:);

  % build directed adjacency matrix
  A = sparse(F,F(:,[2:end 1]),1);
  % Find single occurance edges
  [OI,OJ,OV] = find(A-A');
  % Maintain direction
  O = [OI(OV>0) OJ(OV>0)];%;OJ(OV<0) OI(OV<0)];

end
