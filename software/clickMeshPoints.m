function meshPoints = clickMeshPoints(mesh, image3D, meshColor, cmap, climits)

% clickMeshPoints - displays a mesh and allows the user to select points (Note that the interface is much better in R2013a than in R2015a)
%
% To run the point selector, on the mesh figure click on the point
% selector (the plus sign), select a point on the mesh, and then hit enter 
% to add that postion to the list of bleb positions. Rotations and zooms 
% are enabled via the standard buttons. To continue to the next cell type n.
%
% IMPORTANT NOTE: Please use Matlab R2013a.
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

% close existing figures
close all

% plot the mesh
fig = figure;
colormap(cmap);
caxis(climits);
meshHandle = patch(mesh,'EdgeColor','none','FaceAlpha',1,'FaceColor','flat', 'FaceVertexCData', meshColor);

% color the mesh
%meshHandle.FaceVertexCData = meshColor; 
colormap(cmap);
caxis(climits);

%set(meshHandle,'CLim',climits)
%set(meshHandle,'FaceColor','flat','FaceVertexCData',meshColor,'CDataMapping','direct')

% improve the mesh shine
isonormals(image3D, meshHandle)

% properly set the axis
daspect([1 1 1]); axis off; 

% light the scene
camlookat(meshHandle); 
camlight(0,0); camlight(90,-60); camlight(270,60); camlight(180,0)
%material metal
lighting phong;
rotate3d on;

% select mesh points
datacursormode on
meshPoints = [];
blebs = 1;
while ~strcmp(input(['     Patch ' num2str(blebs) '  '], 's'), 'n')
    dcmObj = datacursormode(fig); % see the help for datacursormode
    cInfo = getCursorInfo(dcmObj);
    meshPoints = [meshPoints; cInfo.Position];
    hold on
    plot3(cInfo.Position(:,1), cInfo.Position(:,2), cInfo.Position(:,3), 'LineStyle', 'none', 'Marker', '.', 'Marker', '.', 'MarkerSize', 30, 'Color', 'y'); 
    blebs = size(meshPoints, 1)+1;
end
datacursormode off
