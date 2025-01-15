function [U,G,I,J] = remove_small_components(V,F,varargin)
  % REMOVE_SMALL_COMPONENTS
  %
  % [V,F,I,J] = remove_small_components(V,F)
  %
  % Inputs:
  %   V  #V by 3 list of vertex positions
  %   F  #F by 3 list of face indices into rows of V
  % Outputs:
  %   U  #U by 3 list of vertex positions
  %   G  #G by 3 list of face indices into rows of U
  %   I  #V by 1 list of indices such that: G = I(F)
  %   J  #G by 1 list of indices into F
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
   
%from gptoolbox https://github.com/alecjacobson/gptoolbox
%  revised by HMF Danuserlab2022

  [~,total_vol] = centroid_gptbx(V,F);
  min_vol = abs(0.1*total_vol);  % updated for Danuser lab, adding abs and 
  % change the 0.0001 to 0.1 for defining small components ,MD & HMF 2022

  [~,C] = connected_components(F);
  nc = max(C);
  vol = zeros(nc,1);
  for i = 1:nc
    Fi = F(C==i,:);
    [~,vol(i)] = centroid_gptbx(V,Fi);
  end
  %vol

  J = find(ismember(C,find(abs(vol)>min_vol)));
  F = F(J,:);
  [U,I] = remove_unreferenced(V,F);
  G = I(F);

