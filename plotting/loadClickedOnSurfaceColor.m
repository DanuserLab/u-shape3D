function meshColor = loadClickedOnSurfaceColor(MD, chan, frame)

% loadClickedOnSurfaceColor - loads the color of a mesh surface colored by SVM score and overlaid with trainer clicks
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

% this is not done!!!!!!!!!!!!!!

% load the training data (hardcoded path to the tester name!!!!!!!!!!!!!!!)
testerName  = 'MeghanCertain';
trainPath = fullfile(MD.outputDirectory_, 'Training Data', testerName, 'blebLocs.mat');
assert(~isempty(dir(trainPath)), 'No saved score found.');
tStruct = load(trainPath);

% check to make sure that click data exists for this frame
assert(ismember(frame, frameIndex), ['There is no click data for this frame. Valid frames: ' num2str(frameIndex)]);
assert(isfield(tStruct{1}.locations, 'blebs'), 'User must have clicked on both blebs and non-blebs');

% load the clicks for this frame
blebClicks = tStruct.locations{frameIndex(frameIndex == frame)}.blebs;
notBlebClicks = tStruct.locations{frameIndex(frameIndex == frame)}.notBlebs;

% load the SVM score 
scorePath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Analysis' filesep 'BlebSegment']; 
scoreName = ['SVMscore_' num2str(chan) '_' num2str(frame) '.mat'];
scorePath = fullfile(scorePath, scoreName);
assert(~isempty(dir(scorePath)), 'No saved score found.');
sStruct = load(scorePath);

% load the surface segmentation
blebPath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Analysis' filesep 'SurfaceSegment']; 
blebName = ['surfaceSegment_' num2str(chan) '_' num2str(frame) '.mat'];
blebPath = fullfile(blebPath, blebName);
assert(~isempty(dir(blebPath)), 'No saved segmentation found.');
bStruct = load(blebPath);

% load the list of neighbors
neighborsPath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Analysis' filesep 'Mesh']; 
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