function [ B ] = barycenter(V, F)
  % BARYCENTER Compute the barycenter of every triangle
  %
  % B = barycenter(V,F)
  %
  % Inputs:
  %   V #V x dim matrix of vertex coordinates
  %   F #F x simplex_size  matrix of indices of triangle corners
  % Output:
  %   B a #F x dim matrix of 3d vertices
  % 
  % See also: quadrature_points
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

  B = zeros(size(F,1),size(V,2));
  for ii = 1:size(F,2)
    B = B + 1/size(F,2) * V(F(:,ii),:);
  end

end

