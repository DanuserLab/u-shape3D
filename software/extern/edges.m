function E = edges(F)
  % EDGES Compute the unique undireced edges of a simplicial complex
  % 
  % E = edges(F)
  %
  % Input:
  %  F #F x simplex-size  matrix of indices of simplex corners
  % Output:
  %  E edges in sorted order, direction of each is also sorted
  %
  % Example:
  %   % get unique undirected edges
  %   E = edges(F);
  %   % get unique directed edges
  %   E = [E ; E(:,2) E(:, 1)];
  % 
  % Copyright 2011, Alec Jacobson (jacobson@inf.ethz.ch)
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

  % all combinations of edges
  n = size(F,2);

  e = nchoosek(1:n,2);
  A = sparse(F(:,e(:,1)),F(:,e(:,2)),1,max(F(:)),max(F(:)));
  [EI,EJ] = find(tril(A+A'));
  E = [EJ EI];

  %I = [];
  %J = [];
  %for ii = 1:(n-1)
  %  I = [I repmat(ii,1,n-ii)];
  %  J = [J (ii+1):n];
  %end
  %assert(all(size(I) == size(J)));

  %% 
  %EI = F(:,I);
  %EI = EI(:);
  %EJ = F(:,J);
  %EJ = EJ(:);

  %E = unique(sort([EI EJ]')','rows');

  %if(size(F,2) == 3)
  %  E = unique(sort( ...
  %    [F(:,1) F(:,2); ...
  %     F(:,1) F(:,3); ...
  %     F(:,2) F(:,3) ...
  %     ]')','rows');
  %elseif(size(F,2) == 4)
  %  E = unique(sort( ...
  %    [F(:,1) F(:,2); ...
  %     F(:,1) F(:,3); ...
  %     F(:,1) F(:,4); ...
  %     F(:,2) F(:,3); ...
  %     F(:,2) F(:,4); ...
  %     F(:,3) F(:,4) ...
  %     ]')','rows');
  %else 
  %  error('F should either be #F by 3 tri list or #F by 4 tet list');
  %end

end

