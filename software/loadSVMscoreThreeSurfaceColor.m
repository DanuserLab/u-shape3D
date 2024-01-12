function meshColor = loadSVMscoreThreeSurfaceColor(MD, chan, frame)

% loadSVMscoreThreeSurfaceColor - loads the color of a mesh surface colored by SVM score binned into three levels
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


% load the SVM score 
% scorePath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Analysis' filesep 'BlebSegment']; 
scorePath = MD.findProcessTag('MotifDetection3DProcess',false, false,'tag',false,'last').outFilePaths_{1,chan}; 
scoreName = ['SVMscore_' num2str(chan) '_' num2str(frame) '.mat'];
scorePath = fullfile(scorePath, scoreName);
assert(~isempty(dir(scorePath)), 'No saved score found.');
sStruct = load(scorePath);

% load the surface segmentation
% blebPath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Analysis' filesep 'SurfaceSegment']; 
blebPath = MD.findProcessTag('SurfaceSegmentation3DProcess',false, false,'tag',false,'last').outFilePaths_{1,chan}; 
blebName = ['surfaceSegment_' num2str(chan) '_' num2str(frame) '.mat'];
blebPath = fullfile(blebPath, blebName);
assert(~isempty(dir(blebPath)), 'No saved segmentation found.');
bStruct = load(blebPath);

% load the list of neighbors
% neighborsPath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Analysis' filesep 'Mesh']; 
neighborsPath = MD.findProcessTag('Mesh3DProcess',false, false,'tag',false,'last').outFilePaths_{1,chan}; 
neighborsName = ['neighbors_' num2str(chan) '_' num2str(frame) '.mat'];
neighborsPath = fullfile(neighborsPath, neighborsName);
assert(~isempty(dir(neighborsPath)), 'No saved list of neighbors was found.');
nStruct = load(neighborsPath);

% determine which faces are on the boundary between segments
onBoundary = findBoundaryFaces(bStruct.surfaceSegment, nStruct.neighbors, 'double');

% make faces that are on the boundary or outside of a segment grey

meshColor = -1*sStruct.SVMscore';
meshColor(meshColor >= 1) = 1;
meshColor(abs(meshColor) < 1) = 0;
meshColor(meshColor <= -1) = -1;
meshColor(onBoundary==1) = -2; % on the boundary