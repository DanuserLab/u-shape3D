function saveDAEfile(image3D, mesh, vertexColorsIndex, cmap, climits, savePath)

% saveDAEfile - saves a colored mesh as a collada dae file
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

% generate and invert the normals
mesh.normals = isonormals(image3D, mesh.vertices, 'negate');

% truncate the colormap
vertexColorsIndex(vertexColorsIndex < climits(1)) = climits(1);
vertexColorsIndex(vertexColorsIndex > climits(2)) = climits(2);

% generate the surface colors
minColor = min(vertexColorsIndex); maxColor = max(vertexColorsIndex);
if numel(cmap) > 3
    vertexColorsRGB = cmap(floor((length(cmap)-1)*((vertexColorsIndex-minColor)/(maxColor-minColor)))+1,:);
else
    vertexColorsRGB = repmat(cmap,length(mesh.vertices),1);
end
vertexColorsRGBA = [vertexColorsRGB, ones(length(vertexColorsRGB),1)];

% find the contents of the dae file
daeContents = makeDAEfile(mesh.vertices, mesh.faces, mesh.normals, vertexColorsRGBA);

% write the text file
fid = fopen(savePath, 'w');
fprintf(fid, daeContents);
fclose(fid);