function meshMovieMD(processOrMovieData, varargin)

% meshMovieMD - creates a triangular surface mesh from a grayscale 3D movie
%
%% INPUTS:
%
% MD                 - a MovieData object that will be deconvolved
%
% p.OutputDirectory  - directory where the deconvolved images will be saved
%
% p.chanList         - a list of the channels that will be analyzed
%
% p.useUndeconvolved - load the raw data rather than the deconvolved data
%
% p.meshMode         - the segmentation and meshing strategy
%    'otsu'          - generates an isosurface from an Otsu value
%    'otsuMultiCell' - use Otsu to segment a single cell within a field
%                      of many cells
%    'otsuSteerable' - combines an Otsu threshold of the image with an Otsu
%                      threshold of the steerable filter response
%    'twoLevelSurface' - combines an inside mask with an Otsu threshold
%    'threeLevelSurface'  - combines Hunter Elliott's surface filter with
%                           an inside mask and an Otsu threshold
%
% p.scaleOtsu        - scales the automatically calculated Otsu threshold
%
% p.imageGamma       - gamma adjust the image prior to Otsu thresholding
%
% p.smoothImageSize  - the std of the Gaussian kernel used to smooth the
%                      image
% 
% p.smoothMeshMode   - if or how the mesh is smoothed
%     'none'         - does not smooth the mesh
%     'curvature'    - smooths the mesh using curvature flow
%
% p.smoothMeshIterations - the number of iterations over which the mesh is
%                          smoothed
%
% p.curvatureMedianFilterRadius - the radius (in pixels) of a real-space 
%                                 median filter that smoothes curvature
%
% p.curvatureSmoothOnMeshIterations - the number of iterations that
%                                     curvature is allowed to diffuse on 
%                                     the mesh geometry                         
%
% p.multicellCellIndex - the index of the cell to analyze in future
%
% p.multicellGaussSizeMultiCell - the standard deviation of the Gaussian
%                                 filter used prior to distinguishing cells 
%
% p.multicellGaussSizeCell - the standard deviation of the Gaussian filter
%                            used for cell segmentation
%
% p.multicellMinAreaMultiCell - the minimum allowed volume of a cell in pixels
%
% p.multicellDilateRadiusMultiCell - the number of pixels by which the cells
%                                    are dilated prior to Otsu thresholding 
%
% p.filterScales - the scales in pixels over which the steerable or surface 
%                  filter is run
%
% p.filterNumStdSurface - the number of standard deviations above the mean
%                         that the surface filter is thresholded at
%
% p.steerableType - the type of steerable filter: 1 for lines and 2 for
%                   surfaces
%
% p.insideGamma - a gamma correction aplied to the image prior to steerable 
%                 or surface filtering
%
% p.insideBlur - the standard deviation of a Gaussian blur of the image for
%                the "inside" mask of the three level segmentation
%
% p.insideDilateRadius - morphological dilation size for the "inside" mask 
%                        of the three level segmentation
%
% p.insideErodeRadius - morphological erosion size for the "inside" mask 
%                       of the three level segmentation
%Check input
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

[MD, process] = getOwnerAndProcess(processOrMovieData,'Mesh3DProcess',true);
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
if ~p.useUndeconvolved
    p.chanList = MeshProcessingProcess.checkValidMeshChannels(process, 'Deconvolution3DProcess');    
end

% ============= Configure InputPaths. ================
inFilePaths = cell(1, numel(MD.channels_));
for j = p.chanList
    if p.useUndeconvolved
        inFilePaths{1,j} = MD.getChannel(j).channelPath_;
    else
        iProc = MD.getProcessIndex('Deconvolution3DProcess');
        inFilePaths{1,j}= MD.processes_{iProc}.outFilePaths_{1,j};
    end
end
process.setInFilePaths(inFilePaths);
% ============= ======================================

% ============= Configure OutputPaths. ================
% initiates directories to store images in
dataDir = p.OutputDirectory;
parameterSaveDir = [p.OutputDirectory filesep '..' filesep 'Parameters']; 
outFilePaths = cell(3, numel(MD.channels_));
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
% ====================================================



% iterate through the images
disp('   Meshing Surfaces');
intensityLevels = zeros(length(MD.channels_), MD.nFrames_);
p_orig = p;
for c = p.chanList
    p = p_orig;
    p.chanList = c;
    p = splitPerChannelParams(p, c);
    parfor t = 1:MD.nFrames_ % can be made a parfor loop   
%     for t = 1:MD.nFrames_ % can be made a parfor loop   

        % display progress
        disp(['      image ' num2str(t) ' (channel ' num2str(c) ')'])
        
        % load the image
        if p.useUndeconvolved
            image3D = im2double(MD.getChannel(c).loadStack(t));
            image3D = make3DImageVoxelsSymmetric(image3D, MD.pixelSize_, MD.pixelSizeZ_);
            %image3D(image3D==0) = NaN;
        else
            % pathDir = [MD.outputDirectory_ filesep 'Morphology' filesep 'Deconvolution'];
            pathDir = inFilePaths{1,c};
            imageName = sprintf('decon_%d_%d.tif', c, t);
            image3D = im2double(load3DImage(pathDir, imageName)); 
            image3D = make3DImageVoxelsSymmetric(image3D, MD.pixelSize_, MD.pixelSizeZ_);
        end
        
        % smooth the image if desired
        if p.smoothImageSize > 0
            image3D = filterGauss3D(image3D, p.smoothImageSize);
        end
        
        % gamma correct the image if desired
        if p.imageGamma ~= 1
            image3D = image3D.^p.imageGamma;
        end
        
        % mesh the image
        surface = []; imageSurface = []; % (for the parfor loop)
        switch p.meshMode
            case 'otsu'
                [surface, imageSurface, intensityLevels(c,t)] = meshOtsu(image3D, p.scaleOtsu);
            case 'otsuMulticell' 
                image3Dmasked = multiCellDetect(image3D, p.multicellGaussSizePreThresh, p.multicellMinVolume, p.multicellDilateRadius, p.multicellCellIndex);
                [surface, imageSurface, intensityLevels(c,t)] = meshOtsu(image3Dmasked, p.scaleOtsu);
            case 'otsuSteerable'
                [steerableResponse, ~, ~, ~] = multiscaleSteerableFilter3D(image3D.^p.insideGamma, p.steerableType, p.filterScales);
                [surface, imageSurface, intensityLevels(c,t)] = combineImagesMeshOtsu(image3D, 'Otsu', steerableResponse, 'Otsu', p.scaleOtsu);
            case 'stdSteerable'
                [steerableResponse, ~, ~, ~] = multiscaleSteerableFilter3D(image3D.^p.insideGamma, p.steerableType, p.filterScales);
                [surface, imageSurface, intensityLevels(c,t)] = combineImagesMeshOtsu(image3D, 'Otsu', steerableResponse, mean(steerableResponse(:))+p.steerableNumStdSurface*std(steerableResponse(:)), p.scaleOtsu);
            case 'twoLevelSurface'
                [surface, imageSurface, intensityLevels(c,t)] = twoLevelSegmentation3D(image3D, p.insideGamma, p.insideBlur, p.insideDilateRadius, p.insideErodeRadius);
            case 'threeLevelSurface'
                [surface, imageSurface, intensityLevels(c,t)] = threeLevelSegmentation3D(image3D, p.filterScales, p.filterNumStdSurface, p.insideGamma, p.insideBlur, p.insideDilateRadius, p.insideErodeRadius);
            otherwise
                error('   Invalid meshMode')
        end
        
        % save the surface image for use in other processes
        parsave(fullfile(outFilePaths{1,c}, ['imageSurface_' num2str(c) '_' num2str(t) '.mat']), imageSurface); % (not a built-in function)
        
        % smooth the mesh 
        switch p.smoothMeshMode
            case 'none'
                % do nothing
            
            case 'curvature'
                if p.smoothMeshIterations > 0 
                    surface = smoothpatch(surface, 1, p.smoothMeshIterations);
                end
                
            otherwise
                error('   Invalid smoothMeshMode')
        end
        
        % save the mesh
        dataName = ['surface_' num2str(c) '_' num2str(t) '.mat'];
        parsave(fullfile(outFilePaths{1,c},dataName), surface); % (not a built-in function)
        
        % measure curvature
        [neighbors, meanCurvature, meanCurvatureUnsmoothed, gaussCurvatureUnsmoothed, faceNormals] = measureCurvature(surface, p.curvatureMedianFilterRadius, p.curvatureSmoothOnMeshIterations);
        
        % save the curvature data 
        dataName = ['neighbors_' num2str(c) '_' num2str(t) '.mat'];
        parsave(fullfile(outFilePaths{1,c},dataName), neighbors); % (not a built-in function)
        dataName = ['meanCurvature_' num2str(c) '_' num2str(t) '.mat'];
        parsave(fullfile(outFilePaths{1,c},dataName), meanCurvature); 
        dataName = ['meanCurvatureUnsmoothed_' num2str(c) '_' num2str(t) '.mat'];
        parsave(fullfile(outFilePaths{1,c},dataName), meanCurvatureUnsmoothed); 
        dataName = ['gaussCurvatureUnsmoothed_' num2str(c) '_' num2str(t) '.mat'];
        parsave(fullfile(outFilePaths{1,c},dataName), gaussCurvatureUnsmoothed); 
        dataName = ['faceNormals_' num2str(c) '_' num2str(t) '.mat'];
        parsave(fullfile(outFilePaths{1,c},dataName), faceNormals); 
        
    end
    [m, h] = plotMeshMD(MD,'surfaceMode','curvature');
    savefig(h, fullfile(outFilePaths{3,c},'meshCurvature.fig'))
end
p = p_orig;
% save data and parameters 
save(fullfile(outFilePaths{4,1}, 'intensityLevels.mat'), 'p', 'intensityLevels');
save(fullfile(outFilePaths{2,1}, 'meshParameters.mat'), 'p');

% [m, h] = plotMeshMD(MD,'surfaceMode','curvature')
% savefig(h, fullfile(outFilePaths{1,c},'meshCurvature.fig'))

