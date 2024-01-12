function meshColor = loadCurvatureSurfaceColor(MD, chan, frame)

% loadCurvatureSurfaceColor - loads the color of a surface colored by curvature for each image
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

% find the path to the mesh color
curvatureConvert = -1000/MD.pixelSize_;
% curvaturePath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Analysis' filesep 'Mesh']; 
curvaturePath = MD.findProcessTag('Mesh3DProcess').outFilePaths_{1,chan}; 

curvaturePath = fullfile(curvaturePath, ['meanCurvature_' num2str(chan) '_' num2str(frame) '.mat']);
assert(~isempty(dir(curvaturePath)), ['Invalid variable path: ' curvaturePath]);

% load the mesh color
cStruct = load(curvaturePath);
meshColor = curvatureConvert*cStruct.meanCurvature;
