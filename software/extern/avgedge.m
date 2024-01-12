function [ b ] = avgedge(V,F)
  % AVGEDGE Compute the average of every edge in the mesh
  % 
  % [ b ] = avgedge(V,F)
  %
  % Inputs:
  %  V  #V x 3 matrix of vertex coordinates
  %  F  #F x #simplex size  list of simplex indices
  % Outputs:
  %  b average edge length
  %
  % Note: boundary edges are weighted half as much as internal edges
  %
  % Copyright 2011, Alec Jacobson (jacobson@inf.ethz.ch), and Daniele Panozzo
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

  
  % works on anything edges.m can handle
  E = edges(F);
  B = normrow(V(E(:,1),:)-V(E(:,2),:));
  
  b = mean(B);

end

