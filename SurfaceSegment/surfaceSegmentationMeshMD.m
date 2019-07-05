function surfaceSegmentationMeshMD(processOrMovieData, varargin)

% surfaceSegmentationMeshMD - segments the cell surface using curvature and volume characteristics
%
%% INPUTS:
%
% MD                - a MovieData object that will be analyzed
%
% p.OutputDirectory - directory where the output will be saved
%
% p.chanList        - a list of the channels that will be analyzed
%
% p.blebMode        - the way in which bleb segmentation is performed
%   triangleMerge:      following spill depth merging, merge regions based on the triangle ratio rule
%   losMerge:           following spill depth merging, merge regions that are mutually visible
%   triangleLosMerge:   following spill depth merging, iteratively merge regions by the triangle rule and the LOS rule
%   triangleLosMergeThenLocal: After triangleLOSMerge, perform a local merge
%
% p.triangleRatio   - a parameter governing watershed merging (see the triangle merger)
%
% p.otsuRatio       - a parameter governing watershed merging (see the spill depth merger)
% 
% p.losRatio        - the mutual visibility above which two adjacent regions will be merged
%
% p.raysPerCompare  - the number of rays sent between regions to measure mutual visibility
%
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
rng('default');
ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('movieData', @(x) isa(x,'Process') && isa(x.getOwner(),'MovieData') || isa(x,'MovieData'));
ip.addOptional('paramsIn',[], @isstruct);
ip.addParameter('ProcessIndex',[],@isnumeric);
ip.parse(processOrMovieData,varargin{:});
paramsIn = ip.Results.paramsIn;

[MD, process] = getOwnerAndProcess(processOrMovieData,'SurfaceSegmentation3DProcess',true);
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
p.chanList = MeshProcessingProcess.checkValidMeshChannels(process, 'Mesh3DProcess');

% ============= Configure InputPaths. ================
inFilePaths = cell(1, numel(MD.channels_));
for j = p.chanList
    meshProc = MD.findProcessTag('Mesh3DProcess',false, false,'tag',false,'last');
    inFilePaths{1,j}= meshProc.outFilePaths_{1,j};
end
process.setInFilePaths(inFilePaths);
% ============= ======================================


disp('   Segmenting cell surface')

% initiates a directory to store curvature segmentation data in
% ============= Configure OutputPaths. ================
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
% ====================================================

% segment curvature
p_orig = p;
for c = p.chanList
    
    p = p_orig;
    p.chanList = c;
    p = splitPerChannelParams(p, c);

    % find the directory where the surfaces and curvatures are stored
%     surfacePath = fullfile(inFilePaths{1,c},['surface_',num2str(c),'_%i.mat']);
%     curvaturePath = fullfile(inFilePaths{1,c},'meanCurvature_%i_%i.mat');
%     neighborsPath = fullfile(inFilePaths{1,c},'neighbors_%i_%i.mat');

    parfor t = 1:MD.nFrames_  % can be made a parfor loop
    
        % display progress
        disp(['      image ' num2str(t) ' (channel ' num2str(c) ')'])
        
        % load the surface and curvature data
        
        surfacePath = fullfile(inFilePaths{1,c},sprintf('surface_%i_%i.mat', c, t));
        curvaturePath = fullfile(inFilePaths{1,c},sprintf('meanCurvature_%i_%i.mat', c, t));
        neighborsPath = fullfile(inFilePaths{1,c},sprintf('neighbors_%i_%i.mat', c, t));
        
        sStruct = load(surfacePath);
        cStruct = load(curvaturePath);
        nStruct = load(neighborsPath);
        
        % initialize variables for the parfor loop
        mergeList = [];
        watersheds = [];
        watershedsSpill = [];
        surfaceSegment = [];
        surfaceSegmentIntermediate = [];
        surfaceSegmentPreLocal = [];
        
        % segment the surface
        switch p.blebMode
            
            case 'triangleMerge'
                [surfaceSegment, watershedsSpill, watersheds] = segmentBlebsTriangle(sStruct.surface, cStruct.meanCurvature, nStruct.neighbors, p.otsuRatio, p.triangleRatio);
                
            case 'losMerge'
                [surfaceSegment, watershedsSpill, watersheds] = segmentBlebsLOS(sStruct.surface, cStruct.meanCurvature, nStruct.neighbors, p.otsuRatio, p.triangleRatio, p.losRatio, p.raysPerCompare);
            
            case 'triangleLosMerge'
                if t == 1 % save the intermediate surface segmentations for only the first frame
                    [mergeList, surfaceSegment, watershedsSpill, watersheds, surfaceSegmentIntermediate] = segmentBlebsLOSiterate(sStruct.surface, cStruct.meanCurvature, nStruct.neighbors, p.otsuRatio, p.triangleRatio, p.losRatio, p.raysPerCompare);
                else
                    [mergeList, surfaceSegment, watershedsSpill, watersheds] = segmentBlebsLOSiterate(sStruct.surface, cStruct.meanCurvature, nStruct.neighbors, p.otsuRatio, p.triangleRatio, p.losRatio, p.raysPerCompare);
                end
                
            case 'triangleLosMergeThenLocal'
                if t == 1 % save the intermediate surface segmentations for only the first frame
                    [mergeList, surfaceSegment, surfaceSegmentPreLocal, watershedsSpill, watersheds, surfaceSegmentIntermediate] = segmentBlebsLOSiterateThenLocal(sStruct.surface, cStruct.meanCurvature, nStruct.neighbors, p.otsuRatio, p.triangleRatio, p.losRatio, p.raysPerCompare);
                else
                    [mergeList, surfaceSegment, surfaceSegmentPreLocal, watershedsSpill, watersheds] = segmentBlebsLOSiterateThenLocal(sStruct.surface, cStruct.meanCurvature, nStruct.neighbors, p.otsuRatio, p.triangleRatio, p.losRatio, p.raysPerCompare);
                end
        end
        
        % save the list of merges for the first frame
        if t == 1
            dataName = ['mergeList_' num2str(c) '_' num2str(t) '.mat'];
            parsave(fullfile(outFilePaths{1,c},dataName), mergeList); % (not a built-in function)
        end
        
        % save the raw watersheds
        dataName = ['watersheds_' num2str(c) '_' num2str(t) '.mat'];
        parsave(fullfile(outFilePaths{1,c},dataName), watersheds); % (not a built-in function)

        % save the watersheds joined by spill depth
        dataName = ['watershedsSpill_' num2str(c) '_' num2str(t) '.mat'];
        parsave(fullfile(outFilePaths{1,c},dataName), watershedsSpill); % (not a built-in function)
        
        % save the segmented curvature
        dataName = ['surfaceSegment_' num2str(c) '_' num2str(t) '.mat'];
        parsave(fullfile(outFilePaths{1,c},dataName), surfaceSegment); % (not a built-in function)
        
        % save the intermediate surface segmentations for the first frame
        if t == 1
            dataName = ['surfaceSegmentIntermediate_' num2str(c) '_' num2str(t) '.mat'];
            parsave(fullfile(outFilePaths{1,c},dataName), surfaceSegmentIntermediate); % (not a built-in function)
            
            if strcmp(p.blebMode, 'triangleLosMergeThenLocal')
                dataName = ['surfaceSegmentPreLocal_' num2str(c) '_' num2str(t) '.mat'];
                parsave(fullfile(outFilePaths{1,c},dataName), surfaceSegmentPreLocal); % (not a built-in function)
            end
        end
        
    end
    [m, h] = plotMeshMD(MD,'surfaceMode','surfaceSegment');
    savefig(h, fullfile(outFilePaths{3,c},'surfaceSegment.fig'))
end

% save parameters 
save(fullfile(outFilePaths{2,1},'surfaceSegmentParameters.mat'), 'p');
