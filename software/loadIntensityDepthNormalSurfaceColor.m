function meshColor = loadIntensityDepthNormalSurfaceColor(MD, chan, frame)

% loadIntensityDepthNormalSurfaceColor - loads the color of a surface colored by intensity for each image
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
% intensityPath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Analysis' filesep 'Intensity']; 
intensityPath = MD.findProcessTag('Intensity3DProcess',false, false,'tag',false,'last').outFilePaths_{1,chan};
intensityPath = fullfile(intensityPath, ['intensity_' num2str(chan) '_' num2str(frame) '.mat']);
assert(~isempty(dir(intensityPath)), ['Invalid variable path: ' intensityPath]);

% load the mesh color
iStruct = load(intensityPath);
meshColor = iStruct.faceIntensities.mean;
