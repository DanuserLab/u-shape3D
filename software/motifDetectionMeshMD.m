function motifDetectionMeshMD(processOrMovieData, varargin)

% motifDetectionMeshMD - classifies the patches morphological motif and calculates motif statistics
%
%% INPUTS:
%
% MD                - a MovieData object that will be analyzed
%
% p.OutputDirectory - directory where the output will be saved
%
% p.chanList        - a list of the channels that will be analyzed
%
% p.calculateShrunk - set to 1 to calculate statistics for shrunk motifs.
%                   Motifs are shrunk by iteratively removing any faces at 
%                   the edge with negatve curvature
%
% p.minMotifSize    - the minimum allowed motif size, measured in number of
%                   triangular faces
%
% p.svmPath         - the path of the SVM model, if used
%
% p.useClicks       - use click data rather than an SVM model to determine 
%                   patch class
%
% p.userClicksName  - the name of the user click data, if used
%
% p.removePatchesSVMpath - the path to an SVM model used to remove patches
%                          that would otherwise be classified as
%                          protrusions, set to [] to not remove any patches
%
% p.usePatchMerge   - set to 1 to use the output of patchMerge rather than the
%                     output of surfaceSegment
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

%% parse inputs 
ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('movieData', @(x) isa(x,'Process') && isa(x.getOwner(),'MovieData') || isa(x,'MovieData'));
ip.addOptional('paramsIn',[], @isstruct);
ip.addParameter('ProcessIndex',[],@isnumeric);
ip.parse(processOrMovieData,varargin{:});
paramsIn = ip.Results.paramsIn;

[MD, process] = getOwnerAndProcess(processOrMovieData,'MotifDetection3DProcess',true);
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


% verify available & valid channels - requires certainprocesses completed.
p.chanList = MeshProcessingProcess.checkValidMeshChannels(process, 'PatchDescription3DProcess');

%% configure input paths
inFilePaths = cell(2, numel(MD.channels_));
for j = p.chanList
    meshProc = MD.findProcessTag('Mesh3DProcess',false, false,'tag',false,'last');
    inFilePaths{1,j}= meshProc.outFilePaths_{1,j};
    segProc = MD.findProcessTag('SurfaceSegmentation3DProcess',false, false,'tag',false,'last');
    inFilePaths{2,j}= segProc.outFilePaths_{1,j};
    if p.usePatchMerge == 1
        patchMergeProc = MD.findProcessTag('PatchMerge3DProcess',false, false,'tag',false,'last');
        inFilePaths{3,j}= patchMergeProc.outFilePaths_{1,j}; 
    end
    patchDescriptProc = MD.findProcessTag('PatchDescription3DProcess',false, false,'tag',false,'last');
    inFilePaths{4,j}= patchDescriptProc.outFilePaths_{3,1}; % see patchDescriptionMeshMD.m
    inFilePaths{5,1} = [p.OutputDirectory filesep '..' filesep 'Parameters'];   
end
process.setInFilePaths(inFilePaths);

% configure output Paths
dataDir = p.OutputDirectory;
parameterSaveDir = [p.OutputDirectory filesep '..' filesep 'Parameters']; 
outFilePaths = cell(4, numel(MD.channels_));
for i = p.chanList    
    outFilePaths{1,i} = [dataDir filesep 'ch' num2str(i)];
    outFilePaths{2,i} = parameterSaveDir;
    outFilePaths{3,i} = [outFilePaths{1,i} filesep 'fig'];
    mkClrDir(outFilePaths{1,i});
    if ~isfolder(outFilePaths{2,i}), mkdirRobust(outFilePaths{2,i}); end
    mkClrDir(outFilePaths{3,i});
end
outFilePaths{4,1} = dataDir;
process.setOutFilePaths(outFilePaths);

%% load the SVMs if needed
clickedOnBlebs = []; clickedOnNotBlebs = [];
if p.useClicks == 0
    if ~iscell(p.svmPath)
        try
            svmStruct = load(p.svmPath);
            inModelAll = svmStruct.inModelAll;
            SVMmodelAll = svmStruct.SVMmodelAll;
        catch
            error(['The following is not a valid SVM path ' p.svmPath]);
        end
    else
        for sp = 1:length(p.svmPath)
            try
                svmStruct = load(p.svmPath{sp});
                inModelAll{sp} = svmStruct.inModelAll;
                SVMmodelAll{sp} = svmStruct.SVMmodelAll;
            catch
                error(['The following is not a valid SVM path ' p.svmPath{sp}]);
            end
        end
    end
    clickedOnBlebs = NaN; clickedOnNotBlebs = NaN; % (for the parfor)
    
    % load an SVM to remove features if needed
    if ~isempty(p.removePatchesSVMpath)
        try
            svmRemoveStruct = load(p.removePatchesSVMpath);
            inModelAllRemove = svmRemoveStruct.inModelAll;
            SVMmodelAllRemove = svmRemoveStruct.SVMmodelAll;
        catch
            error(['The following is not a valid SVM path (remove patches)' p.removePatchesSVMpath]);
        end 
    end
    
% load the user click data if needed
else
    try
        % load the data
        ucStruct = load(fullfile(MD.outputDirectory_, 'TrainingData', p.userClicksName));

        % rename the data
        if isfield(ucStruct,'clickedOnBlebsCell')
            clickedOnBlebs = ucStruct.clickedOnBlebsCell;
        end
        if isfield(ucStruct,'clickedOnNotBlebsCell')
            clickedOnNotBlebs = ucStruct.clickedOnNotBlebsCell;
        end
    catch
        error(['The following is not a userClicks name ' p.userClicksName]);
    end
    inModelAll = NaN; SVMmodelAll = NaN; inModelAllRemove = NaN; SVMmodelAllRemove = NaN; % (needed with the parfor loop)
end

% initialize variables to store statistics in
numChans = length(MD.channels_); numFrames = MD.nFrames_;
blebStats = cell(numChans,numFrames);
cellStatsBleb = cell(1,numChans);
blebStatsShrunk = cell(numChans, numFrames);
cellStatsShrunk = cell(1,numChans, numFrames);

% detect motifs
disp('   Detecting protrusions')
p_orig = p;
for c = p.chanList
    
    p = p_orig;
    p.chanList = c;
    p = splitPerChannelParams(p, c);

    % find the directory where the surfaces and curvatures are stored
%     surfacePath = fullfile(inFilePaths{1,c},'surface_%i_%i.mat');
%     curvaturePath = fullfile(inFilePaths{1,c},'meanCurvature_%i_%i.mat');
%     gaussPath = fullfile(inFilePaths{1,c},'gaussCurvatureUnsmoothed_%i_%i.mat');
%     neighborsPath = fullfile(inFilePaths{1,c},'neighbors_%i_%i.mat');
%     normalsPath = fullfile(inFilePaths{1,c},'faceNormals_%i_%i.mat');
    
    deconParamPath = fullfile(inFilePaths{5,1}, 'deconParameters.mat');
    segmentStatsPath = fullfile(inFilePaths{4,c},'segmentStats.mat');
    
%     if p.usePatchMerge == 1
%         segmentPath = fullfile(inFilePaths{3,c},'surfaceSegment_%i_%i.mat');
%     else
%         segmentPath = fullfile(inFilePaths{2,c},'surfaceSegment_%i_%i.mat');
%     end

    % load the curvature segmentation statistics
    csStatStruct = load(segmentStatsPath);
    stats = csStatStruct.segmentStats;
    cellStats = csStatStruct.cellStats;
    
    % load the deconvolution parameters
    try
        saveP = p; load(deconParamPath); p = saveP; % to not overwrite this function's parameters
    catch
        weinerEstimateList = ones(1,MD.nFrames_);
    end
    if ~exist('weinerEstimateList', 'var'), weinerEstimateList = ones(1,MD.nFrames_); end
    
    for t = 1:MD.nFrames_  % parfor
        
        % display progress
        disp(['      image ' num2str(t) ' (channel ' num2str(c) ')'])
        
        if p.usePatchMerge == 1
            segmentPath = fullfile(inFilePaths{3,c},sprintf('surfaceSegment_%i_%i.mat',c,t));
        else
            segmentPath = fullfile(inFilePaths{2,c},sprintf('surfaceSegment_%i_%i.mat',c,t));
        end  
        
        
        % load the surface data
        csStruct = load(segmentPath);
        if p.usePatchMerge == 1
            surfaceSegment = csStruct.surfaceSegmentPatchMerge; 
        else
            surfaceSegment = csStruct.surfaceSegment; 
        end
        patchList = unique(surfaceSegment);
        
        % make predictions using the SVM model 
        if p.useClicks == 0
            
            if ~iscell(p.svmPath)
                measures = makeMeasuresMatrixSVM(stats, cellStats, inModelAll, weinerEstimateList, c, t, MD.pixelSize_);
                [label,score] = predict(SVMmodelAll, measures); % the score is nonsense for more than 2 classes!!!
            else
                label = []; score1 = []; score2 = [];
                for sp = 1:length(p.svmPath)
                    measures = makeMeasuresMatrixSVM(stats, cellStats, inModelAll{sp}, weinerEstimateList, c, t, MD.pixelSize_);
                    [labelModel, scoreModel] = predict(SVMmodelAll{sp}, measures);
                    label = [label, labelModel];
                    score1 = [score1, scoreModel(:,1)];
                    score2 = [score2, scoreModel(:,2)];
                end
                label = round(mean(label, 2));
                score1 = round(mean(score1, 2));
                score2 = round(mean(score2, 2));
                score = [score1, score2];
            end
            % remove unwanted patches if needed
            if ~isempty(p.removePatchesSVMpath)
                
                % find features to remove
                measuresRemove = makeMeasuresMatrixSVM(stats, cellStats, inModelAllRemove, weinerEstimateList, c, t, MD.pixelSize_);
                [labelRemove,scoreRemove] = predict(SVMmodelAllRemove, measuresRemove);
                
                % remove unwanted features
                label(labelRemove == 1) = 0;
                score(labelRemove == 1) = -1*scoreRemove(labelRemove == 1);
            end
        
        % make predictions based on user clicks
        else 
            if t == 1
                [label,score] = predictFromBlebClicks(clickedOnBlebs{1,t}, clickedOnNotBlebs{1,t}, patchList);
            else % this is a hack!!!!!!!!!!
                label = zeros(1, length(patchList));
                score = label;
            end
        end
        
        % parse the predictions
        SVMscore = nan(1,length(surfaceSegment));
        blebSegment = surfaceSegment;
        if max(label) == 2, blebSegmentLabel = surfaceSegment; end
        for i = 1:length(stats{c,t}.index)
            SVMscore(blebSegment==stats{c,t}.index(i)) = score(i);
            if label(i) == 0
                blebSegment(surfaceSegment==stats{c,t}.index(i)) = 0;
            end
            
            % for two classes, save the patch classification
            if max(label) == 2
                if label(i) == 1
                    blebSegmentLabel(surfaceSegment==stats{c,t}.index(i)) = 1;
                elseif label(i) == 2
                    blebSegmentLabel(surfaceSegment==stats{c,t}.index(i)) = 2;
                else
                    blebSegmentLabel(surfaceSegment==stats{c,t}.index(i)) = 0;
                end
            end
        end
        
        % optionally remove small blebs
        if p.minMotifSize > 0
            blebSegment = removeSmallWatersheds(p.minMotifSize, blebSegment);
        end
        
        % calculate motif statistics
        [blebStats{c,t}, cellStatsBleb{c,t}] = surface2blebStatistics(stats{c,t}, cellStats{c,t}, blebSegment, surfaceSegment);
        
        % save the segmented motifs
        dataName = ['blebSegment_' num2str(c) '_' num2str(t) '.mat'];
        parsave(fullfile(outFilePaths{1,c},dataName), blebSegment); % (not a built-in function)
        
        % save the SVM score
        dataName = ['SVMscore_' num2str(c) '_' num2str(t) '.mat'];
        parsave(fullfile(outFilePaths{1,c},dataName), SVMscore);
        
        % for multiple classes save the label
        if max(label) == 2
            dataName = ['protrusionClass_' num2str(c) '_' num2str(t) '.mat'];
            parsave(fullfile(outFilePaths{1,c},dataName), blebSegmentLabel);
        end
        
        % optionally shrink watersheds
        if p.calculateShrunk
            
            surfacePath = fullfile(inFilePaths{1,c},sprintf('surface_%i_%i.mat', c, t));
            curvaturePath = fullfile(inFilePaths{1,c},sprintf('meanCurvature_%i_%i.mat', c, t));
            neighborsPath = fullfile(inFilePaths{1,c},sprintf('neighbors_%i_%i.mat', c, t));
            gaussPath = fullfile(inFilePaths{1,c},sprintf('gaussCurvatureUnsmoothed_%i_%i.mat',c,t));
            normalsPath = fullfile(inFilePaths{1,c},sprintf('faceNormals_%i_%i.mat',c,t));        
            
            sStruct = load(surfacePath);
            cStruct = load(curvaturePath);
            nStruct = load(neighborsPath);        
            gStruct = load(gaussPath);
            fnStruct = load(normalsPath);
%             csStruct = load(surfaceSegPath);   
            
            
            % load the curvature data
%             cStruct = load(sprintf(curvaturePath, c, t));
            meanCurvature = cStruct.meanCurvature;
%             nStruct = load(sprintf(neighborsPath, c, t));
            neighbors = nStruct.neighbors;
            
            % shrink watersheds
            blebSegmentShrunk = shrinkWatersheds(0, meanCurvature, neighbors, blebSegment, 1);
            
            % load additional data for calculating statistics
%             sStruct = load(sprintf(surfacePath, c, t));
%             cStruct = load(sprintf(curvaturePath, c, t));
%             gStruct = load(sprintf(gaussPath, c, t));
%             nStruct = load(sprintf(neighborsPath, c, t));
%             fnStruct = load(sprintf(normalsPath, c, t));
            
            % calculate statistics
            area = measureAllFaceAreas(sStruct.surface); % measure the area of each face
            [positions, ~] = measureEdgeLengths(sStruct.surface, nStruct.neighbors); % measure the face position and edge lengths in real space
            blebStatsShrunk{c,t} = measureRegionStats(sStruct.surface, positions, blebSegmentShrunk, nStruct.neighbors, cStruct.meanCurvature, gStruct.gaussCurvatureUnsmoothed, fnStruct.faceNormals, area); 
            cellStatsShrunk{c,t} = measureCellStatsStruct(sStruct.surface, area, blebStatsShrunk{c,t});
  
            % save shrunk watersheds
            dataName = ['blebSegmentShrunk_' num2str(c) '_' num2str(t) '.mat'];
            parsave(fullfile(outFilePaths{1,c},dataName), blebSegmentShrunk);
        end
    end
    [m, h] = plotMeshMD(MD,'surfaceMode','protrusions');
    savefig(h, fullfile(outFilePaths{3,c},'protrusions.fig'))    
end

% save data and parameters 
save(fullfile(outFilePaths{2,1},'blebDetectParameters.mat'), 'p');

cellStats = cellStatsBleb;
if p.calculateShrunk
    save(fullfile(outFilePaths{4,1},'blebSegmentStats.mat'), 'blebStats', 'cellStats', 'blebStatsShrunk', 'cellStatsShrunk');
else
    save(fullfile(outFilePaths{4,1},'blebSegmentStats.mat'), 'blebStats', 'cellStats');
end 

