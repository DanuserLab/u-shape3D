function patchDescriptionMeshMD(processOrMovieData, varargin)

% patchDescriptionMeshMD - calculates patch statistics
%
%% INPUTS:
%
% MD                - a MovieData object that will be analyzed
%
% p.OutputDirectory - directory where the output will be saved
%
% p.usePatchMerge   - set to 1 to use the output of patchMerge rather than the
%                     output of surfaceSegment
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

ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('movieData', @(x) isa(x,'Process') && isa(x.getOwner(),'MovieData') || isa(x,'MovieData'));
ip.addOptional('paramsIn',[], @isstruct);
ip.addParameter('ProcessIndex',[],@isnumeric);
ip.parse(processOrMovieData,varargin{:});
paramsIn = ip.Results.paramsIn;

[MD, process] = getOwnerAndProcess(processOrMovieData,'PatchDescription3DProcess',true);
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


% verify available & valid channels - requires Mesh3DProcess completed.
p.chanList = MeshProcessingProcess.checkValidMeshChannels(process, 'SurfaceSegmentation3DProcess');
if p.usePatchMerge == 1
    p.chanList = MeshProcessingProcess.checkValidMeshChannels(process, 'PatchMerge3DProcess');
end

% ==============Configure InputPaths. ================
inFilePaths = cell(2, numel(MD.channels_));
for j = p.chanList
    meshProc = MD.findProcessTag('Mesh3DProcess',false, false,'tag',false,'last');
    inFilePaths{1,j} = meshProc.outFilePaths_{1,j};
    segProc = MD.findProcessTag('SurfaceSegmentation3DProcess',false, false,'tag',false,'last');
    inFilePaths{2,j} = segProc.outFilePaths_{1,j};
    if p.usePatchMerge == 1
        mergDescProc = MD.findProcessTag('PatchMerge3DProcess',false, false,'tag',false,'last');
        inFilePaths{3,j} = mergDescProc.outFilePaths_{1,j};
    end
end
process.setInFilePaths(inFilePaths);
% ====================================================


% initiates a directory to store curvature segmentation data in
% ============= Configure OutputPaths. ================
dataDir = p.OutputDirectory;
parameterSaveDir = [p.OutputDirectory filesep '..' filesep 'Parameters']; 
outFilePaths = cell(3, numel(MD.channels_));
for i = p.chanList    
    outFilePaths{1,i} = [dataDir filesep 'ch' num2str(i)];
    outFilePaths{2,i} = parameterSaveDir;
    mkClrDir(outFilePaths{1,i});
    if ~isfolder(outFilePaths{2,i}), mkdirRobust(outFilePaths{2,i}); end
end
outFilePaths{3,1} = dataDir;
process.setOutFilePaths(outFilePaths);
% ====================================================

% calculate statistics
disp('   Calculating patch statistics')

% initialize variables to store statistics in
numChans = length(MD.channels_); numFrames = MD.nFrames_;
segmentStats = cell(numChans,numFrames);
cellStats = cell(numChans, numFrames);

% iterate through the cells
p_orig = p;
for c = p.chanList
    
    p = p_orig;
    p.chanList = c;
    p = splitPerChannelParams(p, c);

    % find the directory where the surfaces and curvatures are stored
%     surfacePath = fullfile(inFilePaths{1,c},'surface_%i_%i.mat');
%     curvaturePath = fullfile(inFilePaths{1,c},'meanCurvature_%i_%i.mat');
%     neighborsPath = fullfile(inFilePaths{1,c},'neighbors_%i_%i.mat');
    
%     gaussPath = fullfile(inFilePaths{1,c},'gaussCurvatureUnsmoothed_%i_%i.mat');
%     normalsPath = fullfile(inFilePaths{1,c},'faceNormals_%i_%i.mat');
    
%     if p.usePatchMerge == 1
%         surfaceSegPath = fullfile(inFilePaths{3,c},'surfaceSegment_%i_%i.mat');
%     else
%         surfaceSegPath = fullfile(inFilePaths{2,c},'surfaceSegment_%i_%i.mat');
%     end

    parfor t = 1:MD.nFrames_ % parfor
        
        % display progress
        disp(['      image ' num2str(t) ' (channel ' num2str(c) ')'])
        
        surfacePath = fullfile(inFilePaths{1,c},sprintf('surface_%i_%i.mat', c, t));
        curvaturePath = fullfile(inFilePaths{1,c},sprintf('meanCurvature_%i_%i.mat', c, t));
        neighborsPath = fullfile(inFilePaths{1,c},sprintf('neighbors_%i_%i.mat', c, t));
        
        gaussPath = fullfile(inFilePaths{1,c},sprintf('gaussCurvatureUnsmoothed_%i_%i.mat',c,t));
        normalsPath = fullfile(inFilePaths{1,c},sprintf('faceNormals_%i_%i.mat',c,t));

        if p.usePatchMerge == 1
            surfaceSegPath = fullfile(inFilePaths{3,c},sprintf('surfaceSegment_%i_%i.mat',c,t));
        else
            surfaceSegPath = fullfile(inFilePaths{2,c},sprintf('surfaceSegment_%i_%i.mat',c,t));
        end        
        
        sStruct = load(surfacePath);
        cStruct = load(curvaturePath);
        nStruct = load(neighborsPath);        
        
        gStruct = load(gaussPath);
        fnStruct = load(normalsPath);
        csStruct = load(surfaceSegPath);
        
        % load the surface, curvature and patch segmentation data
%         sStruct = load(sprintf(surfacePath, c, t));
%         cStruct = load(sprintf(curvaturePath, c, t));
%         gStruct = load(sprintf(gaussPath, c, t));
%         nStruct = load(sprintf(neighborsPath, c, t));
%         fnStruct = load(sprintf(normalsPath, c, t));
%         csStruct = load(sprintf(surfaceSegPath, c, t));
        
        % find the surface segmentation
        if p.usePatchMerge == 1
            surfaceSegment = csStruct.surfaceSegmentPatchMerge; 
        else
            surfaceSegment = csStruct.surfaceSegment; 
        end
        
        area = measureAllFaceAreas(sStruct.surface); % measure the area of each face
        positions = measureFacePositions(sStruct.surface, nStruct.neighbors); % measure the face positions
        segmentStats{c,t} = measureRegionStats(sStruct.surface, positions, surfaceSegment, nStruct.neighbors, cStruct.meanCurvature, gStruct.gaussCurvatureUnsmoothed, fnStruct.faceNormals, area); 
        cellStats{c,t} = measureCellStatsStruct(sStruct.surface, area, segmentStats{c,t});
        
    end

end

% save data and parameters 
save(fullfile(outFilePaths{2,1},'patchDescribeParameters.mat'), 'p');
save(fullfile(outFilePaths{3,1},'segmentStats.mat'), 'segmentStats', 'cellStats');
