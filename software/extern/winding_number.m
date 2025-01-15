function [W] = winding_number(V,F,O,varargin)
  % WINDING_NUMBER Compute the sum of solid angles of a triangle (tetrahedron)
  % described by points (vectors) V
  % 
  % [W] = winding_number(V,F,O)
  % [W] = winding_number(V,F,O,'ParameterName',ParameterValue, ...)
  %
  % Inputs:
  %  V  #V by 3 list of vertex positions
  %  F  #F by 3 list of triangle indices
  %  O  #O by 3 list of origin positions
  %  Optional inputs:
  %    'Hierarchical'  followed by true or false. Use hierarchical evaluation.
  %      for mex: {true}, for matlab this is not supported 
  %    'Fast' followed by whether to use fast-winding-number {false}
  %    'RayCast' followed by true or flase. Use ray cast version of approximate
  %      evaluation: {false}
  %    'TwoDRays' followed by true or false. Use 2d rays only.
  %    'NumRays' followed by the number of rays to cast for each origin
  % Outputs:
  %  W  no by 1 list of winding numbers
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

  warning('not mex...');
  S = solid_angle(V,F,O);
  W = sum(S,2);
  switch size(F,2)
  case 3
    W = W/(2*pi);
  case 4
    W = W/(4*pi);
  end

end
