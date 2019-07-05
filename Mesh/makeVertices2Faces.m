function vertices2faces = makeVertices2Faces(surface)

% makeVertices2Faces - Construct a list of vertices with the indices of the faces that intersect at each vertex
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


vertices2faces = cell(length(surface.vertices), 1);
for f = 1:size(surface.faces,1)
    vertices2faces{surface.faces(f,1)} = [vertices2faces{surface.faces(f,1)},f];
    vertices2faces{surface.faces(f,2)} = [vertices2faces{surface.faces(f,2)},f];
    vertices2faces{surface.faces(f,3)} = [vertices2faces{surface.faces(f,3)},f];
end
