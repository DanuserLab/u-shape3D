function meshColor = loadMotionSurfaceColor(MD, chan, frame)

% loadMotionSurfaceColor - loads the color of a motion-colored surface for each image
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

% find the path to the mesh color
motionConvert = (60/MD.timeInterval_)/(1000/MD.pixelSize_);
% motionPath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Analysis' filesep 'MeshMotion']; 
motionPath = MD.findProcessTag('MeshMotion3DProcess').outFilePaths_{1,chan}; 
motionPath = fullfile(motionPath, ['motion_' num2str(chan) '_' num2str(frame) '.mat']);
assert(~isempty(dir(motionPath)), ['Invalid variable path: ' motionPath]);

% load the mesh color
mStruct = load(motionPath);
meshColor = motionConvert*mStruct.motion;
meshColor(isnan(meshColor)) = 0;
