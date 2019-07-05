function runKrasBlebSegment()

% runKrasBlebSegment - demonstrates protrusion detection on three kras labeled MV3 cells
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

% Before running, please set the directories in the section below and put the analysis code on Matlab's path.



%% Set directories
imageDirectory = '/home2/mdrisc/Desktop/motif3DExampleDataFinal/testData/krasMV3'; % directory the image is in. The images to be analyzed should be the only thing in the directory.
motifModelDirectory = '/home2/mdrisc/Desktop/motif3DExampleDataFinal/svmModels'; % directory of SVM motif models
psfDirectory = '/home2/mdrisc/Desktop/motif3DExampleDataFinal/PSFs'; % directory of microscope PSFs
saveDirectory = '/home2/mdrisc/Desktop/Motif3DExampleDataFinal/Analysis/krasScript'; % directory for the analysis output


%% Set movie parameters
pixelSizeXY = 160; % in nm
pixelSizeZ = 200; % in nm
timeInterval = 60; % in seconds


%% Turn processes on and off
p.control.resetMD = 0; 
p.control.deconvolution = 1;         p.control.deconvolutionReset = 0;
p.control.computeMIP = 1;            p.control.computeMIPReset = 0;
p.control.mesh = 1;                  p.control.meshReset = 0;
p.control.meshThres = 1;             p.control.meshThresReset = 0;
p.control.surfaceSegment = 1;        p.control.surfaceSegmentReset = 0;
p.control.patchDescribeForMerge = 0; p.control.patchDescribeForMergeReset = 0;
p.control.patchMerge = 0;            p.control.patchMergeReset = 0;
p.control.patchDescribe = 1;         p.control.patchDescribeReset = 0;
p.control.motifDetect = 1;           p.control.motifDetectReset = 0;
p.control.meshMotion = 1;            p.control.meshMotionReset = 0;
p.control.intensity = 1;             p.control.intensityReset = 0;
p.control.intensityBlebCompare = 1; p.control.intensityBlebCompareReset = 0;

cellSegChannel = 1; collagenChannel = 1; p = setChannels(p, cellSegChannel, collagenChannel);


%% Override Default Parameters
p.deconvolution.pathPSF = fullfile(psfDirectory,'meSpimPSF.mat');
p.mesh.imageGamma = 0.7;
p.motifDetect.svmPath = {fullfile(motifModelDirectory,'SVMcertainBleb1'), ... % input more than one motif model to have the models vote
    fullfile(motifModelDirectory, 'SVMcertainBleb2'), ...
    fullfile(motifModelDirectory, 'SVMcertainBleb3')};
%p.motifDetect.svmPath = fullfile(motifModelDirectory,'SVMtestKras');
p.motifDetect.removePatchesSVMpath = fullfile(motifModelDirectory, 'SVMcertainRetractionFiber');
p.intensityBlebCompare.analyzeOnlyFirst = 1;
p.intensityBlebCompare.calculateVonMises = 1;


%% Analyze kras cells
imageList = 1:3;
parfor c = 1:length(imageList) % can be made a parfor loop if sufficient RAM is available.
    disp(['--------- Analysing KRAS Cell ' num2str(imageList(c))])
    
    % load the movie
    if ~isfolder(saveDirectory), mkdir(saveDirectory); end
    imagePathCell = fullfile(imageDirectory,['Cell' num2str(imageList(c))]);
    savePathCell = fullfile(saveDirectory, ['Cell' num2str(imageList(c))]);
    MD = makeMovieDataOneChannel(imagePathCell, savePathCell, pixelSizeXY, pixelSizeZ, timeInterval);

    % analyze the cell
    morphology3D(MD, p)
    
end


%% Make surface renderings
disp('--------- Making Surface Renderings')
for c = 1:length(imageList) % can be made a parfor loop if you only want to export dae files
    savePath = fullfile(saveDirectory, ['Cell' num2str(imageList(c))]);
    
    % to render colored surface meshes in Matlab
    plotMeshMD(savePath, 'surfaceMode', 'curvature'); title('Curvature');
    plotMeshMD(savePath, 'surfaceMode', 'intensity'); title('Kras Intensity');
    plotMeshMD(savePath, 'surfaceMode', 'protrusions'); title('Blebs');
    
%     % to create dae files for export to ChimeraX, uncomment out the
%     % following by removing the first '%' that begins each line
%     % (dae files are saved in "mainSavePath"/krasMV3/Cell#/Morphology/Outputs/Collada)
%     disp('Exporting dae files');
%     plotMeshMD(savePath, 'surfaceMode', 'curvature', 'makeColladaDAE', 1); title('Curvature');
%     plotMeshMD(savePath, 'surfaceMode', 'intensity', 'makeColladaDAE', 1); title('Kras Intensity');
%     plotMeshMD(savePath, 'surfaceMode', 'protrusions', 'makeColladaDAE', 1); title('Blebs');
end


%% Plot analyses (or use runPlotIntensityBlebCompare)
% (Note that more than three images would normally be analyzed to draw robust conclusions.)
disp('--------- Plotting Analyses')
p.savePath = fullfile(saveDirectory, 'analysisFigures');
p.mainDirectory = saveDirectory;
p.cellsList{1} = ['Cell1'];
p.cellsList{2} = ['Cell2'];
p.cellsList{3} = ['Cell3'];
p.analyzeDiffusion = 1; p.analyzeVonMises = 1; p.analyzeDistance = 1;
plotIntensityBlebCompare(p); % see this function for more plots, many plots are commented out
