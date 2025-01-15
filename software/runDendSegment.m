function runDendSegment()

% runDendSegment - demonstrates protrusion detection on a single dendritic cell 
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

% Before running, please set the directories in the section below and put the analysis code on Matlab's path.


%% Set directories
imageDirectory = '/home2/mdrisc/Desktop/Morphology3DPackage/testData/lamDendritic/Cell1'; % directory the image is in. The images to be analyzed should be the only thing in the directory.
motifModelDirectory = '/home2/mdrisc/Desktop/Morphology3DPackage/svmModels'; % directory of SVM motif models
psfDirectory = '/home2/mdrisc/Desktop/Morphology3DPackage/PSFs'; % directory of microscope PSFs
saveDirectory = '/home2/mdrisc/Desktop/Morphology3DPackage/Analysis/lamDendriticScript'; % directory for the analysis output


%% Set movie parameters
pixelSizeXY = 160.099; % in nm
pixelSizeZ = 200; % in nm
timeInterval = 60; % in seconds


%% Turn processes on and off
p.control.resetMD = 0; 
p.control.deconvolution = 1;         p.control.deconvolutionReset = 0;
p.control.computeMIP = 1;            p.control.computeMIPReset = 0;
p.control.mesh = 1;                  p.control.meshReset = 0;
p.control.meshThres = 1;             p.control.meshThresReset = 0;
p.control.surfaceSegment = 1;        p.control.surfaceSegmentReset = 0;
p.control.patchDescribeForMerge = 1; p.control.patchDescribeForMergeReset = 0;
p.control.patchMerge = 1;            p.control.patchMergeReset = 0;
p.control.patchDescribe = 1;         p.control.patchDescribeReset = 0;
p.control.motifDetect = 1;           p.control.motifDetectReset = 0;
p.control.meshMotion = 0;            p.control.meshMotionReset = 0;
p.control.intensity = 0;             p.control.intensityReset = 0;
p.control.intensityBlebCompare = 0; p.control.intensityBlebCompareReset = 0;


%% Override Default Parameters
p.deconvolution.pathPSF = fullfile(psfDirectory,'meSpimPSF.mat');
p.mesh.meshMode = 'threeLevelSurface';
p.surfaceSegment.blebMode = 'triangleLosMergeThenLocal';
p.patchMerge.svmPath = fullfile(motifModelDirectory,'SVMcertainLamPatchMerge.mat');
p.patchDescribe.usePatchMerge = 1;
p.motifDetect.svmPath = fullfile(motifModelDirectory, 'SVMcertainLam.mat');
p.motifDetect.usePatchMerge = 1;
cellSegChannel = 1; collagenChannel = 1; p = setChannels(p, cellSegChannel, collagenChannel);


%% Run the analysis

% load the movie
if ~isfolder(saveDirectory), mkdir(saveDirectory); end
MD = makeMovieDataOneChannel(imageDirectory, saveDirectory, pixelSizeXY, pixelSizeZ, timeInterval);

% analyze the cell
morphology3D(MD, p)

% make figures
plotMeshMD(MD, 'surfaceMode', 'curvature'); title('Curvature');
plotMeshMD(MD, 'surfaceMode', 'protrusions'); title('Motifs');

% to makes a Collada Dae file, remove the '%' symbol below
%plotMeshMD(MD, 'surfaceMode', 'protrusions', 'makeColladaDAE', 1); title('Motifs');


