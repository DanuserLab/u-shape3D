function Ne=vertex_neighbours(FV)
% This function VERTEX_NEIGHBOURS will search in a face list for all 
% the neigbours of each vertex.
%
% Ne=vertex_neighbours(FV)
%
%
% Copyright (C) 2019, Danuser Lab - UTSouthwestern 
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

Ne=vertex_neighbours_double(FV.faces(:,1),FV.faces(:,2),FV.faces(:,3),FV.vertices(:,1),FV.vertices(:,2),FV.vertices(:,3));
