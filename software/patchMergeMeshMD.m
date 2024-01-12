function patchMergeMeshMD(processOrMovieData, varargin)

% patchMergeMeshMD - merges surface patches using machine learning
%
%% INPUTS:
%
% MD - a MovieData object that will be analyzed
%
% p.OutputDirectory - directory where the output will be saved
%
% p.svmPath - the path to the svm model for patch merging
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

%% parse inputs
ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('movieData', @(x) isa(x,'Process') && isa(x.getOwner(),'MovieData') || isa(x,'MovieData'));
ip.addOptional('paramsIn',[], @isstruct);
ip.addParameter('ProcessIndex',[],@isnumeric);
ip.parse(processOrMovieData,varargin{:});
paramsIn = ip.Results.paramsIn;

[MD, process] = getOwnerAndProcess(processOrMovieData,'PatchMerge3DProcess',true);
p = parseProcessParams(process, paramsIn);

% interpret the channels parameter
if ischar(p.channels) && strcmp(p.channels, 'all')
    p.chanList = 1:length(MD.channels_);
elseif isnumeric(p.channels)
    p.chanList = p.channels;
else
    p.chanList = p.ChannelIndex;
end
p = rmfield(p, 'channels');

% verify available & valid channels - requires PatchDescriptionForMerge3DProcess completed.
p.chanList = MeshProcessingProcess.checkValidMeshChannels(process, 'PatchDescriptionForMerge3DProcess');

%% configure input paths
inFilePaths = cell(2, numel(MD.channels_));
for j = p.chanList
    meshProc = MD.findProcessTag('Mesh3DProcess',false, false,'tag',false,'last');
    inFilePaths{1,j} = meshProc.outFilePaths_{1,j};
    segProc = MD.findProcessTag('SurfaceSegmentation3DProcess',false, false,'tag',false,'last');
    inFilePaths{2,j} = segProc.outFilePaths_{1,j};
    mergDescProc = MD.findProcessTag('PatchDescriptionForMerge3DProcess',false, false,'tag',false,'last');
    inFilePaths{3,j} = mergDescProc.outFilePaths_{1,j};
end
process.setInFilePaths(inFilePaths);

% configure output paths
dataDir = p.OutputDirectory;
parameterSaveDir = [p.OutputDirectory filesep '..' filesep 'Parameters']; 
outFilePaths = cell(2, numel(MD.channels_));
for i = p.chanList    
    outFilePaths{1,i} = [dataDir filesep 'ch' num2str(i)];
    outFilePaths{2,i} = parameterSaveDir;
    outFilePaths{3,i} = [outFilePaths{1,i} filesep 'fig'];
    mkClrDir(outFilePaths{1,i});
    if ~isfolder(outFilePaths{2,i}), mkdirRobust(outFilePaths{2,i}); end
    mkClrDir(outFilePaths{3,i});
end
process.setOutFilePaths(outFilePaths);

% merge patches
p_orig = p;
for c = p.chanList
    
    p = p_orig;
    p.chanList = c;
    p = splitPerChannelParams(p, c);

    % load the SVM for patch merging
    try
        svmStruct = load(p.svmPath);
    catch
        error(['The following is not a valid SVM path ' p.svmPath]);
    end

    % find the directory where the surfaces and curvatures are stored
    surfacePath = fullfile(inFilePaths{1,c},'surface_%i_%i.mat');
    curvaturePath = fullfile(inFilePaths{1,c},'meanCurvature_%i_%i.mat');
    curvatureUnsmoothedPath = fullfile(inFilePaths{1,c},'meanCurvatureUnsmoothed_%i_%i.mat');
    gaussPath = fullfile(inFilePaths{1,c},'gaussCurvatureUnsmoothed_%i_%i.mat');
    neighborsPath = fullfile(inFilePaths{1,c},'neighbors_%i_%i.mat');
    surfaceSegPath = fullfile(inFilePaths{2,c},'surfaceSegment_%i_%i.mat');
    pairStatsPath = fullfile(inFilePaths{3,c},'pairStats_%i_%i.mat');

    parfor t = 1:MD.nFrames_ % parfor
        
        % display progress
        disp(['      image ' num2str(t) ' (channel ' num2str(c) ')'])
        
        % load the surface, curvature and patch segmentation data
        sStruct = load(sprintfPath(surfacePath, c, t));
        cStruct = load(sprintfPath(curvaturePath, c, t));
        cuStruct = load(sprintfPath(curvatureUnsmoothedPath, c, t));
        gStruct = load(sprintfPath(gaussPath, c, t));
        nStruct = load(sprintfPath(neighborsPath, c, t));
        csStruct = load(sprintfPath(surfaceSegPath, c, t));
        psStruct = load(sprintfPath(pairStatsPath, c, t));
        
        % merge patches using an SVM
        surfaceSegmentPatchMerge = mergePatchesSVM(sStruct.surface, csStruct.surfaceSegment, psStruct.pairStats, svmStruct.inModelAll, svmStruct.SVMmodelAll, nStruct.neighbors, cStruct.meanCurvature, cuStruct.meanCurvatureUnsmoothed, gStruct.gaussCurvatureUnsmoothed, MD.pixelSize_);
        
        % save the surface segmentation
        dataName = ['surfaceSegment_' num2str(c) '_' num2str(t) '.mat'];
        parsave(fullfile(outFilePaths{1,c},dataName), surfaceSegmentPatchMerge); % (not a built-in function)
        
    end
    [m, h] = plotMeshMD(MD,'surfaceMode','surfaceSegmentPatchMerge');
    savefig(h, fullfile(outFilePaths{3,c},'surfaceSegmentPatchMerge.fig'))
end

% save the parameters 
save(fullfile(outFilePaths{2,1},'patchMergeParameters.mat'), 'p');
