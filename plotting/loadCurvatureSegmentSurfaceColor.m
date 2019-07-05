function meshColor = loadCurvatureSegmentSurfaceColor(MD, chan, frame, colorKey)

% loadCurvatureSegmentSurfaceColor - loads the color of a mesh surface colored by curvature segmentation
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


% load the surface segmentation
blebPath = MD.findProcessTag('SurfaceSegmentation3DProcess').outFilePaths_{1,chan}; 
% blebPath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Analysis' filesep 'SurfaceSegment']; 
blebName = ['surfaceSegment_' num2str(chan) '_' num2str(frame) '.mat'];
blebPath = fullfile(blebPath, blebName);
assert(~isempty(dir(blebPath)), 'No saved segmentation found.');
bStruct = load(blebPath);

% load the list of neighbors
neighborsPath = MD.findProcessTag('Mesh3DProcess').outFilePaths_{1,chan}; 
% neighborsPath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Analysis' filesep 'Mesh']; 
neighborsName = ['neighbors_' num2str(chan) '_' num2str(frame) '.mat'];
neighborsPath = fullfile(neighborsPath, neighborsName);
assert(~isempty(dir(neighborsPath)), 'No saved list of neighbors was found.');
nStruct = load(neighborsPath);

% determine which faces are on the boundary between segments
onBoundary = findBoundaryFaces(bStruct.surfaceSegment, nStruct.neighbors, 'double');

% make faces that are on the boundary or outside of a segment grey
meshColor = mod(bStruct.surfaceSegment*colorKey,1024)+1;
meshColor(bStruct.surfaceSegment<1) = 0; % outside of a bleb
meshColor(onBoundary==1) = 0; % on the boundary