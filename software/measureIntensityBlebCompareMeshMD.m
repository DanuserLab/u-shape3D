function measureIntensityBlebCompareMeshMD(processOrMovieData, varargin)

% measureIntensityBlebCompareMeshMD - measure bleb intensity correlations
%
%% INPUTS:
%
% MD                     - a MovieData object that will be analyzed
%
% p.OutputDirectory      - directory where the output will be saved
%
% p.chanList             - a list of the channels that will be analyzed 
%
% p.analyzeOnlyFirst     - set to true to analyze only the first frame in
%                          each series
%
% p.analyzeOtherChannel  - set to true to analyze the intensity in the 
%                          other channel too
%
% p.analyzeForwardsMotion - set to true to analyze the forwards motion as
%                           well as the regular motion
%
% p.calculateVonMises    - set to true to calculate the von Mises-Fisher
%                          parameter for protrusions in various ways
% 
% p.calculateProtrusionDiffusion - set to true to calculate the diffusion
%                                    of protrusions along the surface 
%
% p.numDiffusionIterations - number of times the protrusions are diffused 
%
% p.calculateDistanceTransformProtrusions - set to true to calculate the
%                                           distance transform of the 
%                                           protrusions segmentation
%
%
% Note: There are assumed to be only two classes.
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

[MD, process] = getOwnerAndProcess(processOrMovieData,'IntensityMotifCompare3DProcess',true);
p = parseProcessParams(process, paramsIn);

% interpret the channels parameter
if ischar(p.channels) && strcmp(p.channels, 'all')
    if p.ChannelIndex == 1:length(MD.channels_)
        p.chanList = 1:length(MD.channels_);
    else
        p.chanList = p.ChannelIndex;
    end
elseif isnumeric(p.channels)
    p.chanList = p.channels;
else
    p.chanList = p.ChannelIndex;
end
p = rmfield(p, 'channels');

% verify available & valid channels - requires Intensity3DProcess completed.
p.chanList = MeshProcessingProcess.checkValidMeshChannels(process, 'Intensity3DProcess');

%% configure input paths
inFilePaths = cell(5, numel(MD.channels_));
for j = p.chanList
    meshProc = MD.findProcessTag('Mesh3DProcess',false, false,'tag',false,'last');
    inFilePaths{1,j} = meshProc.outFilePaths_{1,j};
    inFilePaths{2,j} = meshProc.outFilePaths_{4,1}; % summary stats

    meshProc = MD.findProcessTag('SurfaceSegmentation3DProcess',false, false,'tag',false,'last');
    inFilePaths{3,j} = meshProc.outFilePaths_{1,j};

    motifDetProc = MD.findProcessTag('MotifDetection3DProcess',false, false,'tag',false,'last');
    inFilePaths{4,j} = motifDetProc.outFilePaths_{1,j};

    motifDetProc = MD.findProcessTag('Intensity3DProcess',false, false,'tag',false,'last');
    inFilePaths{5,j} = motifDetProc.outFilePaths_{1,j};

    motionProc = MD.findProcessTag('MeshMotion3DProcess',false, false,'tag',false,'last');
    inFilePaths{6,j} = motionProc.outFilePaths_{1,j};
end
process.setInFilePaths(inFilePaths);

% configure output paths
dataDir = p.OutputDirectory;
parameterSaveDir = [p.OutputDirectory filesep '..' filesep 'Parameters']; 
outFilePaths = cell(4, numel(MD.channels_));
for i = p.chanList    
    outFilePaths{1,i} = [dataDir filesep 'ch' num2str(i)];
    outFilePaths{2,i} = parameterSaveDir;
    outFilePaths{3,i} = [outFilePaths{1,i} filesep 'fig'];
    outFilePaths{4,i} = dataDir;
    mkClrDir(outFilePaths{1,i});
    if ~isfolder(outFilePaths{2,i}), mkdirRobust(outFilePaths{2,i}); end
    mkClrDir(outFilePaths{3,i});
end
process.setOutFilePaths(outFilePaths);

%% analyze data
disp('   Measuring intensity-protrusion correlations')

% load the Otsu threshold levels for the surface images
if p.calculateVonMises == 1    
    levels = load(fullfile(inFilePaths{2,1},'intensityLevels.mat'));
end

% find the last frame to analyze
if p.analyzeOnlyFirst == 1
    lastFrame = 1;
else
    lastFrame = MD.nFrames_;
end

% set the distance values for calculating intensity as a function of
% distance from the cell edge
distVals = 0:0.5:500;
valsAtDist = cell(length(distVals), 1);
valsAtDistBackgroundSubtract = cell(length(distVals), 1);

% find the conversion factors for the cell
convert = [];
if ~isempty(MD.timeInterval_)
    convert.motion = (60/MD.timeInterval_)./(1000/MD.pixelSize_);
else
    convert.motion = NaN;
end
convert.curvature = -1000/MD.pixelSize_;
convert.volume = (MD.pixelSize_/1000)^3;
convert.edgeLengthMeshPixels = [];
convert.edgeLength = [];

%% initialize variables (comparePatches stores patch statistics and
% compareFaces stores data defined at every face)
comparePatches.isProtrusion = [];
comparePatches.isCertainProtrusion = [];
comparePatches.meanIntensity = [];
comparePatches.maxIntensity = [];
comparePatches.meanMotion = [];
comparePatches.surfaceArea = [];
comparePatches.minCurvature = [];
comparePatches.volume = [];
comparePatches.SVMscore = [];
compareFaces.isProtrusion = [];
compareFaces.isCertainProtrusion = [];
compareFaces.curvature = [];
compareFaces.intensity = [];
compareFaces.High = [];
compareFaces.intensityNormal = [];
compareFaces.motion = [];
compareFaces.svmScore = [];

if p.calculateProtrusionDiffusion == 1
    compareFaces.diffusedProtrusions = [];
    compareFaces.diffusedSVM = [];
end

if p.calculateDistanceTransformProtrusions == 1
    compareFaces.distanceTransformProtrusions = [];
end

if p.analyzeOtherChannel == 1
    comparePatches.meanIntensityOther = [];
    comparePatches.maxIntensityOther = [];
    compareFaces.intensityOther = [];
    compareFaces.intensityOtherNormal = [];
end

if p.analyzeForwardsMotion == 1
    comparePatches.meanForwardsMotion = [];
    compareFaces.forwardsMotion = [];
end

vonMises = [];
if p.calculateVonMises == 1
    vonMises.blebCenters = [];
    vonMises.blebs = [];
    vonMises.blebsRand = [];
    vonMises.surface = [];
    vonMises.intensity = [];
    vonMises.intensityPixel = [];
    vonMises.intensityMin = [];
    vonMises.highIntensity = [];
    vonMises.negCurvature = [];
    vonMises.motion= [];
    vonMises.posMotion= [];
    vonMises.intensityDiscrete= [];
    vonMises.intensityRandDiscrete= [];
end

% iterate through the images
p_orig = p;
for c = p.chanList
    
    p = p_orig;
    p.chanList = c;
    p = splitPerChannelParams(p, c);

    % set directories where data is stored
%     surfacePath = fullfile(inFilePaths{1,c},'surface_%i_%i.mat');
%     surfaceImagePath = fullfile(inFilePaths{1,c},'imageSurface_%i_%i.mat');
%     curvaturePath = fullfile(inFilePaths{1,c},'meanCurvature_%i_%i.mat');
%     neighborsPath = fullfile(inFilePaths{1,c},'neighbors_%i_%i.mat');
%     segmentPath = fullfile(inFilePaths{3,c},'surfaceSegment_%i_%i.mat');
%     blebPath = fullfile(inFilePaths{4,c},'blebSegment_%i_%i.mat');
%     scorePath = fullfile(inFilePaths{4,c},'SVMscore_%i_%i.mat');
%     intensityPath = fullfile(inFilePaths{5,c},'intensity_%i_%i.mat');
%     meshMotionPath = fullfile(inFilePaths{6,c} ,'motion_%i_%i.mat');
%     meshForwardsMotionPath = fullfile(inFilePaths{6,c} ,'motionForwards_%i_%i.mat');

    for t = 1:lastFrame
        % display progress
        disp(['      image ' num2str(t) ' (channel ' num2str(c) ')'])  
        
        surfacePath = fullfile(inFilePaths{1,c},sprintf('surface_%i_%i.mat', c, t));
        surfaceImagePath = fullfile(inFilePaths{1,c},sprintf('imageSurface_%i_%i.mat', c, t));
        curvaturePath = fullfile(inFilePaths{1,c},sprintf('meanCurvature_%i_%i.mat', c, t));
        neighborsPath = fullfile(inFilePaths{1,c},sprintf('neighbors_%i_%i.mat', c, t));
        segmentPath = fullfile(inFilePaths{3,c},sprintf('surfaceSegment_%i_%i.mat', c, t));
        blebPath = fullfile(inFilePaths{4,c},sprintf('blebSegment_%i_%i.mat', c, t));
        scorePath = fullfile(inFilePaths{4,c},sprintf('SVMscore_%i_%i.mat', c, t));
        intensityPath = fullfile(inFilePaths{5,c},sprintf('intensity_%i_%i.mat', c, t));
        meshMotionPath = fullfile(inFilePaths{6,c} ,sprintf('motion_%i_%i.mat', c, t));
        meshForwardsMotionPath = fullfile(inFilePaths{6,c} ,sprintf('motionForwards_%i_%i.mat', c, t));                
%         gaussPath = fullfile(inFilePaths{1,c},sprintf('gaussCurvatureUnsmoothed_%i_%i.mat',c,t));
%         normalsPath = fullfile(inFilePaths{1,c},sprintf('faceNormals_%i_%i.mat',c,t));       
        
        % load the surface
        sStruct = load(surfacePath);
        surface = sStruct.surface;
        
        % load the surface segmentation
        ssStruct = load(segmentPath);
        surfaceSegment = ssStruct.surfaceSegment;
        
        % load the neighbor information
        nStruct = load(neighborsPath);
        neighbors = nStruct.neighbors;
        
        % load the curvature
        cStruct = load(curvaturePath);
        curvature = cStruct.meanCurvature;
        compareFaces.curvature = [compareFaces.curvature, curvature'];
        
        % load and save the bleb segmentation
        bStruct = load(blebPath);
        blebSegment = bStruct.blebSegment;
        compareFaces.isProtrusion = [compareFaces.isProtrusion, double(logical(blebSegment'))];
        
        % load and save the SVM score
        ssStruct = load(scorePath);
        SVMscore = ssStruct.SVMscore;
        compareFaces.svmScore = [compareFaces.svmScore, SVMscore];

        % load and save the intensities
        iStruct = load(intensityPath);
        intensity = iStruct.faceIntensities.mean;
        intensityNormal = intensity./mean(intensity(:)); % normalize intensity
        compareFaces.intensity = [compareFaces.intensity, intensity'];
        compareFaces.intensityNormal = [compareFaces.intensityNormal, intensityNormal'];
        if p.analyzeOtherChannel == 1
%             intensityPath = fullfile(inFilePaths{5,c},sprintf('intensity_%i_%i.mat', c, t));
            iStruct = load(fullfile(inFilePaths{5,c},sprintf('intensity_%i_%i.mat', mod(c,2)+1, t))); % assumes there are only two channels!!!!
            intensityOther = iStruct.faceIntensities.mean;
            intensityOtherNormal = intensityOther./mean(intensityOther(:)); % normalize intensityOther
            compareFaces.intensityOther = [compareFaces.intensityOther, intensityOther'];
            compareFaces.intensityOtherNormal = [compareFaces.intensityOtherNormal, intensityOtherNormal'];
        end

        % load and save the mesh motion 
        try 
            mmStruct = load(meshMotionPath);
            motion = mmStruct.motion;
            if t==1, motion = motion'; end
            compareFaces.motion = [compareFaces.motion, motion'];
        catch
            error('Failed to load motion data');
        end
        
        % load and save the forwards motion 
        if p.analyzeForwardsMotion == 1
            mfmStruct = load(meshForwardsMotionPath);
            forwardsMotion = mfmStruct.motionForwards;
            if t==MD.nFrames_, forwardsMotion = forwardsMotion'; end
            compareFaces.forwardsMotion = [compareFaces.forwardsMotion, forwardsMotion'];
        end
        
        % load the surface image
        if p.calculateVonMises == 1      
            siStruct = load(surfaceImagePath);
            surfaceImage = siStruct.imageSurface; 
        end
         
        % load the raw image (for the debug plots and intensity as a function of distance from edge)
        image3D = im2double(MD.getChannel(c).loadStack(t));
        image3D = make3DImageVoxelsSymmetric(image3D, MD.pixelSize_, MD.pixelSizeZ_);
        image3D = addBlackBorder(image3D,1);
        
        % calculate the intensity as a function of distance from the edge
        distImage = bwdist(~(surfaceImage>levels.intensityLevels(c,t)));
        image3Dbackground = image3D - median(image3D(surfaceImage>levels.intensityLevels(c,t))) - 2*std(image3D(surfaceImage>levels.intensityLevels(c,t)));
        image3Dbackground(image3Dbackground < 0) = 0;
        for d = 2:length(distVals)
            valsAtDist{d} = [valsAtDist{d}; image3D(distImage>distVals(d-1) & distImage<=distVals(d))];
            valsAtDistBackgroundSubtract{d} = [valsAtDistBackgroundSubtract{d}; image3Dbackground(distImage>distVals(d-1) & distImage<=distVals(d))];
        end
        clear image3Dbackground
        
        % find the average edge length on the mesh (in pixels)
        convert.edgeLengthMeshPixels = findMeanEdgeLength(surface);
        
        % find the average distance between faces (in pixels)
        facePositions = measureFacePositions(surface, neighbors);
        convert.edgeLength = measureMeanFaceDistance(facePositions, neighbors);

        % find all the patch indices
        patchList = unique(surfaceSegment(surfaceSegment>0)); 
 
        % find the protrusion indices
        protrusionList = unique(blebSegment(blebSegment>0));      
         
        % to calculate patch statistics, measure the area of the faces        
        areas = measureAllFaceAreas(surface);
        
        % initialize variables to calculate patch statistics
        isProtrusion = zeros(1,length(patchList));
        meanIntensity = NaN(1,length(patchList));
        maxIntensity = NaN(1,length(patchList));
        meanMotion = NaN(1,length(patchList));
        surfaceArea = NaN(1,length(patchList));
        minCurvature = NaN(1,length(patchList));
        volume = NaN(1,length(patchList));
        SVMscorePatch = NaN(1,length(patchList));
        if p.analyzeOtherChannel == 1
            meanIntensityOther = NaN(1,length(patchList));
            maxIntensityOther = NaN(1,length(patchList));
        end
        if p.analyzeForwardsMotion == 1
            meanForwardsMotion = NaN(1,length(patchList));
        end
        
        % iterate through the patches to calculate statistics 
        % (why not use the statistics calculated by surfaceSegment?)
        for r = 1:length(patchList)
            
            % determine which patches are protrusions
            if ismember(patchList(r), protrusionList)
                isProtrusion(1,r) = 1;
            end
            
            % find the mean intensity of the patch
            meanIntensity(1,r) = mean(intensityNormal(surfaceSegment==patchList(r)));
            
            % find the max intensity of the patch
            maxIntensity(1,r) = max(intensityNormal(surfaceSegment==patchList(r)));
            
            try 
            % find the mean motion of the patch
                meanMotion(1,r) = mean(motion(surfaceSegment==patchList(r)));
            catch
            end
            
            % find the surface area of the patch
            surfaceArea(1,r) = sum(areas(surfaceSegment==patchList(r)));
            
            % find the min curvature of the patch
            minCurvature(1,r) = min(curvature(surfaceSegment==patchList(r)));
            
            % find the volume of the patch
            [~, ~, closedMesh] = closeMesh(patchList(r), surface, surfaceSegment, neighbors);
            volume(1,r) = measureMeshVolume(closedMesh); 
            
            % find the SVM score of the patch
            SVMscorePatch(1,r) = mode(SVMscore(surfaceSegment==patchList(r)));
            
            % analyze the intensity in the other channel
            if p.analyzeOtherChannel == 1
                meanIntensityOther(1,r) = mean(intensityOther(surfaceSegment==patchList(r)));
                maxIntensityOther(1,r) = max(intensityOther(surfaceSegment==patchList(r)));
            end
            
            % analyze the forwards motion
            if p.analyzeForwardsMotion == 1
                meanForwardsMotion = mean(forwardsMotion(surfaceSegment==patchList(r)));
            end
            
        end
        comparePatches.isProtrusion = [comparePatches.isProtrusion, isProtrusion];
        comparePatches.meanIntensity = [comparePatches.meanIntensity, meanIntensity];
        comparePatches.maxIntensity = [comparePatches.maxIntensity, maxIntensity];
        comparePatches.meanMotion = [comparePatches.meanMotion, meanMotion];
        comparePatches.surfaceArea = [comparePatches.surfaceArea, surfaceArea];
        comparePatches.minCurvature = [comparePatches.minCurvature, minCurvature];
        comparePatches.volume = [comparePatches.volume, volume];
        comparePatches.SVMscore = [comparePatches.SVMscore, SVMscorePatch];
        if p.analyzeOtherChannel == 1
            comparePatches.meanIntensityOther = [comparePatches.meanIntensityOther, meanIntensityOther];
            comparePatches.maxIntensityOther = [comparePatches.maxIntensityOther, maxIntensityOther];
        end
        if p.analyzeForwardsMotion == 1
            comparePatches.meanForwardsMotion = [comparePatches.meanForwardsMotion, meanForwardsMotion];
        end
        
        % determine which faces are certainly protrusions
        isCertainProtrusionFaces = zeros(1,length(SVMscore));
        isCertainProtrusionFaces(SVMscore <= -1) = 1; % protrusions
        isCertainProtrusionFaces(SVMscore >= 1) = -1; % not protrusions
        compareFaces.isCertainProtrusion = [compareFaces.isCertainProtrusion, isCertainProtrusionFaces];
        
        % determine which patches are certainly protrusions
        isCertainProtrusionPatches = zeros(1,length(patchList));
        isCertainProtrusionPatches(SVMscorePatch <= -1) = 1; % protrusions
        isCertainProtrusionPatches(SVMscorePatch >= 1) = -1; % not protrusions
        comparePatches.isCertainProtrusion = [comparePatches.isCertainProtrusion, isCertainProtrusionPatches];
        
        % diffuse bleb locations on the mesh
        if p.calculateProtrusionDiffusion
            
            % smooth blebSegment on the mesh
            diffusedProtrusions = smoothDataOnMesh(surface, neighbors, blebSegment>0, p.numDiffusionIterations);
            compareFaces.diffusedProtrusions = [compareFaces.diffusedProtrusions, diffusedProtrusions'];
            
            % normalize the SVM score
            SVMscoreNormal = (-1*SVMscore+1)/2;
            SVMscoreNormal(SVMscoreNormal > 1) = 1;
            SVMscoreNormal(SVMscoreNormal < 0) = 0;
            
            % smooth blebSegment on the mesh
            diffusedSVM = smoothDataOnMesh(surface, neighbors, SVMscoreNormal', p.numDiffusionIterations);
            compareFaces.diffusedSVM = [compareFaces.diffusedSVM, diffusedSVM'];         
                        
%             % plot the protrusions (debug code)
%             figure;
%             imageName = 'imageSurface_%i_%i.mat';
%             meshPath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Analysis' filesep 'Mesh'];
%             imagePath = fullfile(meshPath, sprintf(imageName, c, t));
%             iStruct = load(imagePath);
%             image3D = iStruct.imageSurface;
%             cmap = colormap(parula);
%             climits = [0 max(diffusedProtrusions)];
%             light_handle = plotMeshFigure(image3D, surface, double(blebSegment>0), cmap, climits, 1);
%             title('Blebs')
%             colormap(hot); colorbar; 
%             
%             % plot the diffusion (debug code)
%             figure;
%             imageName = 'imageSurface_%i_%i.mat';
%             meshPath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Analysis' filesep 'Mesh'];
%             imagePath = fullfile(meshPath, sprintf(imageName, c, t));
%             iStruct = load(imagePath);
%             image3D = iStruct.imageSurface;
%             cmap = colormap(parula);
%             climits = [0 max(diffusedProtrusions)];
%             light_handle = plotMeshFigure(image3D, surface, diffusedProtrusions, cmap, climits, 1);
%             title('Protrusions Diffusion')
%             colormap(hot); colorbar;
%             1;
            
%             % plot the intensity (debug code)
%             figure
%             imageName = 'imageSurface_%i_%i.mat';
%             meshPath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Analysis' filesep 'Mesh'];
%             imagePath = fullfile(meshPath, sprintf(imageName, c, t));
%             iStruct = load(imagePath);
%             image3D = iStruct.imageSurface;
%             cmap = colormap(hot);
%             climits = [min(intensity) max(intensity)];
%             light_handle = plotMeshFigure(image3D, surface, intensity, cmap, climits, 1);
%             title('Intensity')
%             1;

        end
        
        % measure the distance transform of the mesh using the protrusions data
        if p.calculateDistanceTransformProtrusions == 1
            surfaceForDistance = surfaceSegment;
            surfaceForDistance(blebSegment == 0) = 123456789; % this is a hack
            distances = distanceTransformPatches(surfaceForDistance, neighbors);
            compareFaces.distanceTransformProtrusions = [compareFaces.distanceTransformProtrusions, distances'];
                      
%             % plot the distance transform (debug code)
%             figure;
%             imageName = 'imageSurface_%i_%i.mat';
%             meshPath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Analysis' filesep 'Mesh'];
%             imagePath = fullfile(meshPath, sprintf(imageName, c, t));
%             iStruct = load(imagePath);
%             image3D = iStruct.imageSurface;
%             cmap = colormap(hot);
%             climits = [min(distances) max(distances)];
%             light_handle = plotMeshFigure(image3D, surface, distances, cmap, climits, 1);
%             title('distances')
%             1;
        end
        
% calculate von-Mises-Fisher parameters
        if p.calculateVonMises == 1
            
            % find the face within each bleb that is farthest from the bleb edge
            regionCenters = findRegionCentersFarthest(neighbors, blebSegment, curvature);
            regionCentersFull = zeros(size(curvature));
            regionCentersFull(regionCenters(:,1)) = 1;
            
            % find the locations of the bleb centers
            blebLocations = facePositions(logical(regionCentersFull), :);
            
            % find the location within the cell that is farthest from the cell edge
            [~, cellCenter] = findInteriorMostPoint(surfaceImage > levels.intensityLevels(c, t));
            
            % generate vectors on the unit sphere to represent the blebs
            blebVectors = (blebLocations - repmat([cellCenter(2) cellCenter(1) cellCenter(3)], size(blebLocations, 1), 1));
            blebVectors = blebVectors./repmat(sqrt(sum(blebVectors.^2,2)), 1, 3);
            
            % calculate the bleb polarization (von Mises-Fisher on bleb centers)
            [meanBlebCentersVM, concBlebCentersVM] = estimateVonMisesFisherParameters(blebVectors, 3);
            vonMises.blebCenters = [vonMises.blebCenters; meanBlebCentersVM, concBlebCentersVM];
            
            % calculate the bleb polarization (von Mises-Fisher on all blebby faces)
            blebyFaces = facePositions(blebSegment>0, :);
            blebyFaceVectors = (blebyFaces - repmat([cellCenter(2) cellCenter(1) cellCenter(3)], size(blebyFaces, 1), 1));
            blebyFaceVectors = blebyFaceVectors./repmat(sqrt(sum(blebyFaceVectors.^2,2)), 1, 3);
            [meanBlebVM, concBlebVM] = estimateVonMisesFisherParameters(blebyFaceVectors, 3);
            vonMises.blebs = [vonMises.blebs; meanBlebVM, concBlebVM];
            
            % calculate the surface polarization (von Mises-Fisher on all faces)
            allFaceVectors = (facePositions - repmat([cellCenter(2) cellCenter(1) cellCenter(3)], size(facePositions, 1), 1));
            allFaceVectors = allFaceVectors./repmat(sqrt(sum(allFaceVectors.^2,2)), 1, 3);
            [meanSurfaceVM, concSurfaceVM] = estimateVonMisesFisherParameters(allFaceVectors, 3);
            vonMises.surface = [vonMises.surface; meanSurfaceVM, concSurfaceVM];
            
            % calculate the intensity polarization (weighted von Mises-Fisher on all faces)
            allFaceVectors = (facePositions - repmat([cellCenter(2) cellCenter(1) cellCenter(3)], size(facePositions, 1), 1));
            allFaceVectors = allFaceVectors./repmat(sqrt(sum(allFaceVectors.^2,2)), 1, 3);
            [meanIntensityVM, concIntensityVM] = estimateVonMisesFisherParametersWeighted(allFaceVectors, intensity, 3);
            vonMises.intensity = [vonMises.intensity; meanIntensityVM, concIntensityVM];
            [meanIntensityMinVM, concIntensityMinVM] = estimateVonMisesFisherParametersWeighted(allFaceVectors, intensity-min(intensity(:)), 3);
            vonMises.intensityMin = [vonMises.intensityMin; meanIntensityMinVM, concIntensityMinVM];
            
            % calculate the high intensity polarization (weighted von Mises-Fisher on all faces)
            allFaceVectors = (facePositions - repmat([cellCenter(2) cellCenter(1) cellCenter(3)], size(facePositions, 1), 1));
            allFaceVectors = allFaceVectors./repmat(sqrt(sum(allFaceVectors.^2,2)), 1, 3);
            intensity90 = prctile(intensity,90);
            highIntensity = intensity; highIntensity(highIntensity < intensity90) = 0;
            [meanHighIntensityVM, concHighIntensityVM] = estimateVonMisesFisherParametersWeighted(allFaceVectors, highIntensity, 3);
            vonMises.highIntensity = [vonMises.highIntensity; meanHighIntensityVM, concHighIntensityVM];
          
            % calculate the motion polarization (weighted von Mises-Fisher on all faces)
            allFaceVectors = (facePositions - repmat([cellCenter(2) cellCenter(1) cellCenter(3)], size(facePositions, 1), 1));
            allFaceVectors = allFaceVectors./repmat(sqrt(sum(allFaceVectors.^2,2)), 1, 3);
            [meanMotionVM, concMotionVM] = estimateVonMisesFisherParametersWeighted(allFaceVectors, motion, 3);
            vonMises.motion = [vonMises.motion; meanMotionVM, concMotionVM];
            
            % calculate the positive motion polarization (weighted von Mises-Fisher on all faces)
            allFaceVectors = (facePositions - repmat([cellCenter(2) cellCenter(1) cellCenter(3)], size(facePositions, 1), 1));
            allFaceVectors = allFaceVectors./repmat(sqrt(sum(allFaceVectors.^2,2)), 1, 3);
            posMotion = motion; posMotion(posMotion<0) = 0;
            [meanPosMotionVM, concPosMotionVM] = estimateVonMisesFisherParametersWeighted(allFaceVectors, posMotion, 3);
            vonMises.posMotion = [vonMises.posMotion; meanPosMotionVM, concPosMotionVM];
            
            % calculate the intensity polarization on the surface
            discreteLevels = 32;
            %[meanIntensityDiscreteVM, concIntensityDiscreteVM] = measureVonMisesDiscrete(allFaceVectors, 2, 2, intensity, discreteLevels);
            %vonMises.intensityDiscrete = [vonMises.intensityDiscrete; meanIntensityDiscreteVM, concIntensityDiscreteVM];
            
            % measure the intensity polarization of the data and a control
            meanIntensityDiscreteVM = nan(100,3); concIntensityDiscreteVM = nan(100,1);
            parfor r = 1:100
                [meanIntensityDiscreteVM(r,:), concIntensityDiscreteVM(r)] = measureVonMisesDiscrete(allFaceVectors, 1000, 10*(r-1)+1, intensity, discreteLevels);
            end
            vonMises.intensityDiscrete = [vonMises.intensityDiscrete; meanIntensityDiscreteVM, concIntensityDiscreteVM];
            
            meanIntensityRandDiscreteVM = nan(100,3); concIntensityRandDiscreteVM = nan(100,1);
            parfor r = 1:100
                [xRand, yRand, zRand] = sph2cart(2*pi*rand(length(allFaceVectors),1), 2*pi*rand(length(allFaceVectors),1), 1);
                randFaceVectors = [xRand, yRand, zRand];
                [meanIntensityRandDiscreteVM(r,:), concIntensityRandDiscreteVM(r)] = measureVonMisesDiscrete(randFaceVectors, 1000, 10*(r-1)+1, intensity, discreteLevels);
            end
            vonMises.intensityRandDiscrete = [vonMises.intensityRandDiscrete; meanIntensityRandDiscreteVM, concIntensityRandDiscreteVM];
            
%             % calculate the intensity polarization (pixelwise)
%             discreteLevels = 256;
%             [meanIntensityPixelVM, concIntensityPixelVM] = measurePixelwiseIntensityVonMises(image3D, surfaceImage, levels.intensityLevels(c,t), discreteLevels, cellCenter);
%             vonMises.intensityPixel = [vonMises.intensityPixel; meanIntensityPixelVM, concIntensityPixelVM];
            
            % calculate the negative curvature polarization (weighted von Mises-Fisher on all faces)
            negCurvature = convert.curvature*curvature;
            %negCurvature(negCurvature > -1) = 0;
            curvatureFaceVectors = [];
            curvatureFaceVectors(:,1) = allFaceVectors(negCurvature<-1,1);
            curvatureFaceVectors(:,2) = allFaceVectors(negCurvature<-1,2);
            curvatureFaceVectors(:,3) = allFaceVectors(negCurvature<-1,3);
            negCurvature(negCurvature >= -1) = [];
            negCurvature = abs(negCurvature);
            [meanNegCurvatureVM, concNegCurvatureVM] = estimateVonMisesFisherParametersWeighted(curvatureFaceVectors, negCurvature, 3);
            vonMises.negCurvature = [vonMises.negCurvature; meanNegCurvatureVM, concNegCurvatureVM];
            
            % calculate the polarization for 200 surfaces where patches are randomally assigned to be blebby
            numShuffles = 200;
            for nS = 1:numShuffles
               
                % randomally permute isProtrusion
                isProtrusionRand = isProtrusion(randperm(length(isProtrusion)));
                
                % iterate through the patches
                isProtrusionFacesRand = zeros(1,length(surfaceSegment), 'logical');
                for pat = 1:length(patchList)
                    
                    % set a patch to 1 if indicated by isProtrusionRand
                    if isProtrusionRand(pat) == 1 
                        isProtrusionFacesRand(surfaceSegment == patchList(pat)) = 1;
                    end
                end
                
                % calculate the von Mises-Fisher parameter
                blebyFaces = facePositions(isProtrusionFacesRand, :);
                blebyFaceVectors = (blebyFaces - repmat([cellCenter(2) cellCenter(1) cellCenter(3)], size(blebyFaces, 1), 1));
                blebyFaceVectors = blebyFaceVectors./repmat(sqrt(sum(blebyFaceVectors.^2,2)), 1, 3);
                [meanBlebVM, concBlebVM] = estimateVonMisesFisherParameters(blebyFaceVectors, 3);
                vonMises.blebsRand = [vonMises.blebsRand; meanBlebVM, concBlebVM];
            end
            
%             % calculate the standard deviation of intensity about each face
%             intensityImage = image3D.*imfill(imageMasked, 'holes');
%             spreadIntensity = calculateImageStandardDeviationAboutLocations(intensityImage, facePositions);
%             
%             % plot the spread in intensity (debug code)
%             figure;
%             imageName = 'imageSurface_%i_%i.mat';
%             meshPath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Analysis' filesep 'Mesh'];
%             imagePath = fullfile(meshPath, sprintf(imageName, c, t));
%             iStruct = load(imagePath);
%             image3D = iStruct.imageSurface;
%             cmap = colormap(parula);
%             climits = [min(spreadIntensity) max(spreadIntensity)];
%             light_handle = plotMeshFigure(image3D, surface, spreadIntensity, cmap, climits);
%             title('Intensity spread')
        
        end


    end
end
convert.edgeLength = (MD.pixelSize_/1000)*mean(convert.edgeLength);

% 
% 
% % find the intensities and bleb densities above mean() + 3*std() % was 3
% intensityCutoffHigh = mean(compare.allIntensities)+2*std(compare.allIntensities);
% intensityCutoffLow = mean(compare.allIntensities)+0*std(compare.allIntensities);
% compareList.blebDensityNearIntensity = allBlebDensities(compare.allIntensities>intensityCutoffHigh);
% compareList.blebDensityAwayFromIntensity = allBlebDensities(compare.allIntensities<intensityCutoffLow);
% %motionNearIntensity = allMotion(allIntensities>intensityCutoffHigh);
% %motionAwayFromIntensity = allMotion(allIntensities<intensityCutoffLow);
% %length(motionNearIntensity)/(length(motionNearIntensity)+length(motionAwayFromIntensity))

% % assemble data for saving
% channel = 1;
% SVMscore = [compare.SVMscorePatch{channel,:}];
% meanIntensity = [compare.meanIntensity{channel,:}];
% maxIntensity = [compare.maxIntensity{channel,:}];
% surfaceArea = [compare.surfaceArea{channel,:}];
% volume = [compare.volume{channel,:}];
% compareList.meanBlebIntensity = meanIntensity(SVMscore >= 0.5);
% compareList.meanNonBlebIntensity = meanIntensity(SVMscore < 0.5);
% compareList.meanCertainBlebIntensity = meanIntensity(SVMscore >= 1);
% compareList.meanCertainNonBlebIntensity = meanIntensity(SVMscore <= 0);
% compareList.maxBlebIntensity = maxIntensity(SVMscore >= 0.5);
% compareList.maxNonBlebIntensity = maxIntensity(SVMscore < 0.5);
% compareList.maxCertainBlebIntensity = maxIntensity(SVMscore >= 1);
% compareList.maxCertainNonBlebIntensity = maxIntensity(SVMscore <= 0);
% compareList.blebSurfaceArea = surfaceArea(SVMscore >= 0.5);
% compareList.nonBlebSurfaceArea = surfaceArea(SVMscore < 0.5);
% compareList.certainBlebSurfaceArea = surfaceArea(SVMscore >= 1);
% compareList.certainNonBlebSurfaceArea = surfaceArea(SVMscore <= 0);
% compareList.blebVolume = volume(SVMscore >= 0.5);
% compareList.nonBlebVolume = volume(SVMscore < 0.5);


% used for Gaudenz' grant
% % make histograms of the blebDensity near and away from high intensities
% figure
% g = histogram(compareList.blebDensityNearIntensity, 46, 'Normalization', 'probability', 'DisplayStyle', 'Stairs');
% hold on
% h = histogram(compareList.blebDensityAwayFromIntensity, g.BinEdges, 'Normalization', 'probability', 'DisplayStyle', 'Stairs');
% legend('High Intensity', 'Low Intensity')
% title('Bleb Density')
% 
% % plot the distributions of blebDensity near and away from high intensities
% figure
% plot((g.BinEdges(1:end-1)+g.BinEdges(2:end))/2, g.Values, 'LineWidth', 2, 'Color', [178, 24, 43]./255);
% hold on
% plot((h.BinEdges(1:end-1)+h.BinEdges(2:end))/2, h.Values, 'LineWidth', 2, 'Color', [33, 102, 172]./255);
% legend('High Intensity', 'Low Intensity')
% xlabel('Normalized Bleb Surface Density')
% ylabel('Normalized Frequency')
% % 
% % make histograms of the motion near and away from high intensities
% figure
% binEdges = -15.25:0.5:18.25;
% j = histogram(motionNearIntensity, binEdges, 'Normalization', 'probability', 'DisplayStyle', 'Stairs');
% hold on
% k = histogram(motionAwayFromIntensity, j.BinEdges, 'Normalization', 'probability', 'DisplayStyle', 'Stairs');
% legend('High PI3K', 'Low PI3K')
% title('Protrusive/Retractive Motion')
% 
% % plot the distributions of blebDensity near and away from high intensities
% figure
% convertMotion = 0.398;
% toPlotX = convertMotion*(j.BinEdges(1:end-1)+j.BinEdges(2:end))/2;
% toPlotY1 = j.Values; toPlotY2 = k.Values;
% toPlotY1(toPlotX==0) = []; 
% toPlotY2(toPlotX==0) = []; 
% toPlotX(toPlotX==0) = []; 
% plot(toPlotX, toPlotY1, 'LineWidth', 2, 'Color', [178, 24, 43]./255);
% hold on
% plot(toPlotX, toPlotY2, 'LineWidth', 2, 'Color', [33, 102, 172]./255);
% legend('High Intensity', 'Low Intensity')
% xlabel('Protrusive/Retractive Motion (um/min)')
% ylabel('Normalized Frequency')

% % set the channel
%channel = 1;

% figure
% histogram2([compare.blebSurfaceArea{channel,:}], [compare.maxBlebIntensity{channel,:}], 5, 'faceColor', 'flat')
% xlabel('Bleb Surface Area (square pixels)')
% ylabel('Max Bleb Intensity'); colormap(jet);
% 
% figure
% histogram2([compare.blebSurfaceArea{channel,:}], [compare.meanBlebIntensity{channel,:}], 5, 'faceColor', 'flat')
% xlabel('Bleb Surface Area (square pixels)')
% ylabel('Mean Bleb Intensity'); colormap(jet);
% 
% figure
% histogram2([compare.closureDistance{channel,:}], [compare.maxBlebIntensity{channel,:}], 5, 'faceColor', 'flat')
% xlabel('Closure distance (pixels)')
% ylabel('Max Bleb Intensity'); colormap(jet);
% 
% figure
% histogram2([compare.blebVolume{channel,:}], [compare.maxBlebIntensity{channel,:}], 5, 'faceColor', 'flat')
% xlabel('Bleb volume (cubic pixels)')
% ylabel('Max Bleb Intensity'); colormap(jet);
% 
% figure
% histogram2(-1.*[compare.minCurvature{channel,:}], [compare.maxBlebIntensity{channel,:}], 5, 'faceColor', 'flat')
% xlabel('Max Curvature')
% ylabel('Max Bleb Intensity'); colormap(jet);
% 
% figure
% histogram2(allIntensities, allMotion, 100, 'faceColor', 'flat')
% xlabel('Face Intensity')
% ylabel('Face Motion'); colormap(jet);
% 
% figure
% histogram2(-1.*[compare.minCurvature{channel,:}], [compare.meanBlebIntensity{channel,:}], 5, 'faceColor', 'flat')
% xlabel('Max Curvature')
% ylabel('Mean Bleb Intensity'); colormap(jet);
% 
% figure
% h = histogram([compare.meanBlebIntensity{channel,:}], 8, 'Normalization', 'probability');
% hold on
% histogram([compare.meanNonBlebIntensity{channel,:}], h.BinEdges, 'Normalization', 'probability');
% legend({'bleb', 'nonBleb'});
% %xlabel('Mean Bleb Intensity')
% xlabel('Mean Bleb and Non-Bleb Intensity'); colormap(jet);
% 
% figure
% g = histogram([compare.maxBlebIntensity{channel,:}], 8, 'Normalization', 'probability');
% hold on
% histogram([compare.maxNonBlebIntensity{channel,:}], g.BinEdges, 'Normalization', 'probability');
% legend({'bleb', 'nonBleb'});
% %xlabel('Mean Bleb Intensity')
% xlabel('Max Bleb and Non-Bleb Intensity'); colormap(jet);


% figure
% histogram2([blebVolume{:}], [maxBlebIntensity{:}], 'faceColor', 'flat')
% xlabel('Bleb Volume')
% ylabel('Max Bleb Intensity'); colormap(jet);
% 
% % figure
% % plot([blebVolume{:}], [maxBlebIntensity{:}], 'LineStyle', 'none', 'Marker', '.')
% % xlabel('Bleb Volume (cubic pixels)')
% % ylabel('Max Bleb Intensity')
% % 
% % figure
% % plot(cellfun(@median, blebSurfaceArea), 'Marker', 'x')
% % title('Median bleb surface area over time')
% % 
% % figure
% % plot(cellfun(@length, blebSurfaceArea), 'Marker', 'x')
% % title('Bleb count over time')
% % 
% % figure
% % plot(maxIntensity, 'Marker', 'x')
% % title('Maximum intensity over time')
% % 
% % plot mean curvatue vs intensity for all the faces
% plot(abs(curvature(1:10:end)), intensity(1:10:end)-1, 'LineStyle', 'none', 'Marker', '.', 'MarkerSize', 1)
% xlabel('Curvature')
% ylabel('Intensity')

% % plot mean intensity vs intensityOther for the first time point
% figure
% plot(meanBlebIntensityOther{1}, meanBlebIntensity{1}, 'LineStyle', 'none', 'Marker', '.');
% xlabel('Mean Actin Intensity')
% ylabel('Mean Cytosol Intensity')
% axis equal

% % plot max intensity vs intensityOther for the first time point
% % (use this to make the tractin-cytosol plot)
% %figure
% hold on
% plot(compare.maxBlebIntensityOther{1,1}, compare.maxBlebIntensity{1,1}, 'LineStyle', 'none', 'Marker', 'o', 'MarkerSize', 2);
% xlabel('Max Actin Intensity')
% ylabel('Max Cytosol Intensity')
% axis equal
% axis([0 3 0 3])
% hold on

% % plot the normalized actin intensity (kind of boring plot)
% figure
% histogram(meanBlebIntensityOther{1}./meanBlebIntensity{1})
% title('Normalized Actin Intensity')
% 
% % plot a double histogram of intensity and intensityOther
% figure
% h = histogram(meanBlebIntensityOther{1}, 30, 'Normalization', 'probability');
% hold on
% histogram(meanBlebIntensity{1}, h.BinEdges, 'Normalization', 'probability')
% legend('Actin', 'Cytosol')
% title('Actin-Cytosol Intensity')

% save the compare variables
save(fullfile(outFilePaths{4,1}, 'stats.mat'), 'comparePatches', 'compareFaces', 'vonMises', 'convert');

% save parameters 
save(fullfile(outFilePaths{2,1}, 'intensityBlebCompareParameters.mat'), 'p');
