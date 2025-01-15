function [surface, normals] = readDAEfile(filePath)

% readDAEfile - read a DAE file and convert it into a mesh
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

% read the file into a string
daeText = fileread(filePath);

% find the vertices
[~, firstDigit] = regexp(daeText, '<float_array id="shape0-lib-positions-array" count="\d*">\d');
[~,lastDigit] = regexp(daeText, '<float_array id="shape0-lib-positions-array" count="\d*">[-e.\d\s]*');
vertices = str2num(daeText(firstDigit:lastDigit));
vertices = reshape(vertices, 3, []);
surface.vertices = vertices';

% find the vertices
[~, firstDigit] = regexp(daeText, '<float_array id="shape0-lib-normals-array" count="\d*">[-\d]');
[~,lastDigit] = regexp(daeText, '<float_array id="shape0-lib-normals-array" count="\d*">[-e.\d\s]*');
normals = str2num(daeText(firstDigit:lastDigit));
normals = reshape(normals, 3, []);
normals = normals';

% find the faces
[~, firstDigit] = regexp(daeText, '<p>\d');
[~,lastDigit] = regexp(daeText, '<p>[\d\s]*');
faces = str2num(daeText(firstDigit:lastDigit)) + 1;
faces = reshape(faces, 2, []);
faces = reshape(faces(1,:), 3, []);
surface.faces = faces';
% 
% % debugging plot
% figure
% patch('Faces',surface.faces, 'Vertices',surface.vertices, 'FaceColor','red', 'EdgeColor','none')
% daspect([1,1,1])
% axis tight
% camlight
% camlight(-80,-10)
% lighting gouraud