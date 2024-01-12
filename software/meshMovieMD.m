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
%    'threeLevelSurface' - combines Hunter Elliott's surface filter with
%                          an inside mask and an Otsu threshold
%    'readDaeFile'   - rather than generate a mesh, loads a mesh saved as a 
%                      collada DAE file
%    'readObjFile'   - rather than generate a mesh, loads a mesh saved as a 
%                      collada OBJ file
%    'readPlyFile'   - rather than generate a mesh, loads a mesh saved as a 
%                      collada PLY file
%
%    'loadMask' - loads and blurs a mask to create the mesh from
%
% p.registerImages   - set to 1 to register the images prior to meshing
%
% p.saveRawImages    - set to 1 to register and save the raw images
%
% p.saveRawSubtractedImages - set to 1 to register and save raw images with
%                             the previous image subtracted from each image
%
% p.registrationMode - type of registration used, if registration is
%                      enabled. Options: 'translation', 'rigid', 'affine'
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
% p.saveCurvatureImage - set to 1 to save an image where each pixel has the
%                        average curvature of the faces at its location
%
% p.saveEdgeImage - set to 1 to save an image of just the pixels near the
%                   edge
%
% p.saveRawSubtractedImages - save the raw frame t+1 minus the raw frame t
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
% 
% p.daeFilePath - the path to a mesh stored as a dae file. Only used if
%                 meshMode is readDaeFile
% 
% p.objFilePath - the path to a mesh stored as a obj file. Only used if
%                 meshMode is readObjFile
% 
% p.plyFilePath - the path to a mesh stored as a ply file. Only used if
%                 meshMode is readPlyFile
% 
% p.maskDir - the directoty of an optional mask to load
%
% p.maskName - the name of an optional mask to load (saved as an image)
% 
% p.removeSmallComponents - a flag to remove the small mesh components
%% parse inputs
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

%%TODO 
%% check p.chanList is not empty
assert(~isempty(p.chanList), 'channel list is empty!') 

%% configure input paths
inFilePaths = cell(1, numel(MD.channels_));
for j = p.chanList
    if p.useUndeconvolved
        inFilePaths{1,j} = MD.getChannel(j).channelPath_;
    else
        iProc = MD.getProcessIndex('Deconvolution3DProcess');
        inFilePaths{1,j}= MD.processes_{iProc}.outFilePaths_{1,j};
    end
    pathDir = [MD.outputDirectory_ filesep 'Morphology' filesep 'Deconvolution']; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
process.setInFilePaths(inFilePaths);


% configure output paths
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

%% create a surface mesh
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
            %image3D(image3D==0) = NaN;
        else
            % pathDir = [MD.outputDirectory_ filesep 'Morphology' filesep 'Deconvolution'];
            pathDir = inFilePaths{1,c};
            imageName = sprintf('decon_%d_%d.tif', c, t);
            image3D = im2double(load3DImage(pathDir, imageName)); 
        end
              
        % for the parfor loop
        imageOffset = [];
        image3Draw = [];
        image3DrawRegister = [];
        image3DnotApodized = [];
        
        % load the non-apodized image if wanted
        if strcmp(p.meshMode, 'threeLevelSurfaceMultiApo') == 1
            pathDir = inFilePaths{1,c};
            imageName = sprintf('deconNotApodized_%d_%d.tif', c, t);
            image3DnotApodized = im2double(load3DImage(pathDir, imageName)); 
        end
        
        % make the image isotropic
        image3D = make3DImageVoxelsSymmetric(image3D, MD.pixelSize_, MD.pixelSizeZ_);
        if strcmp(p.meshMode, 'threeLevelSurfaceMultiApo') == 1
            image3DnotApodized = make3DImageVoxelsSymmetric(image3DnotApodized, MD.pixelSize_, MD.pixelSizeZ_);
        end
        
        % smooth the image if desired
        if p.smoothImageSize > 0
            image3D = filterGauss3D(image3D, p.smoothImageSize);
            if strcmp(p.meshMode, 'threeLevelSurfaceMultiApo') == 1
                image3DnotApodized = filterGauss3D(image3DnotApodized, p.smoothImageSize);
            end
        end
        
        % gamma correct the image if desired
        if p.imageGamma ~= 1
            image3D = image3D.^p.imageGamma;
            if strcmp(p.meshMode, 'threeLevelSurfaceMultiApo') == 1
                image3DnotApodized = image3DnotApodized.^p.imageGamma;
            end
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
            case 'threeLevelSurfaceMultiApo'
%                 [~, imageSurface, ~] = twoLevelSegmentation3D(image3D, p.insideGamma, p.insideBlur, p.insideDilateRadius, p.insideErodeRadius);
%                 image3DnotApodized = filterGauss3D(image3DnotApodized, 0.6);
%                 [steerableResponse, ~, ~, ~] = multiscaleSteerableFilter3D(image3DnotApodized.^p.insideGamma, p.steerableType, p.filterScales);
%                 [surface, imageSurface, intensityLevels(c,t)] = combineImagesMeshOtsu(imageSurface, 'Otsu', steerableResponse, 'Otsu', p.scaleOtsu);
%                 
                %[surface, imageSurface, intensityLevels(c,t)] = threeLevelMultiApoSegmentation3D(image3D, image3DnotApodized, p.insideGamma, p.insideBlur, p.insideDilateRadius, p.insideErodeRadius);
                %image3DnotApodized = image3DnotApodized.^0.8;
                image3DnotApodized = filterGauss3D(image3DnotApodized, 1.5);
                [surface, imageSurface, intensityLevels(c,t)] = threeLevelSteerableSegmentation3D(image3D, image3DnotApodized, p.steerableType, p.filterScales, p.insideGamma, p.insideBlur, p.insideDilateRadius, p.insideErodeRadius);
            case 'readDaeFile'
                [surface, ~] = readDAEfile(p.daeFilePath);
                surface.faces = [surface.faces(:,2), surface.faces(:,1), surface.faces(:,3)];
                [~, imageSurface, intensityLevels(c,t)] = meshOtsu(image3D, p.scaleOtsu)
           case 'readObjFile'
                [surface.vertices surface.faces] = readOBJ(p.objFilePath);
                [~, imageSurface, intensityLevels(c,t)] = meshOtsu(image3D, p.scaleOtsu);
          case 'readPlyFile'
                [surface.vertices surface.faces] = read_ply(p.plyFilePath);
                [~, imageSurface, intensityLevels(c,t)] = meshOtsu(image3D, p.scaleOtsu);
            case 'loadMask'
                image3D = im2double(load3DImage(p.maskDir, [p.maskName num2str(t-1) '.tif'])); 
                image3D = make3DImageVoxelsSymmetric(image3D, MD.pixelSize_, MD.pixelSizeZ_);
                image3D = filterGauss3D(image3D, p.smoothImageSize);
                [surface, imageSurface, intensityLevels(c,t)] = meshOtsu(image3D, p.scaleOtsu);
            case 'activeContour'
%                 [image3D, level] = prepareCellOtsuSeg(image3D);
%                 sphereDilateSE = makeSphere3D(15);
%                 imageMask = imdilate(image3D>level, sphereDilateSE);
                imageMask = zeros(size(image3D));
                imageMask(25:end-25,25:end-25, 25:end-25) = 1;
                image3D = activecontour(1000*image3D,imageMask,2000, 'edge');
                image3D = filterGauss3D(image3D, 0.5);
                [surface, imageSurface, intensityLevels(c,t)] = meshOtsu(image3D, p.scaleOtsu);
            otherwise
                error('   Invalid meshMode')
        end
        % remove small componnets from the mesh - HMF2022
        if p.removeSmallComponents
            [surface.vertices surface.faces] = remove_small_components(surface.vertices,surface.faces);
        end 
        % register the image by making the interior most point the cell center (this works better than standard registration for 
        % movies where the protrusions change quickly relative to the frame rate and are large compared to the cell size)
        if p.registerImages
            [~, cellCenter] = findInteriorMostPoint(imageSurface>intensityLevels(c,t));
            imageCenter = ceil(size(imageSurface)/2);
            imageOffset = cellCenter-imageCenter;
            imageSurface = imtranslate(imageSurface, [-imageOffset(2), -imageOffset(1), -imageOffset(3)]);
            surface = isosurface(imageSurface, intensityLevels(c,t)); % this is a hack!!!!!!!!
            %surface.vertices = surface.vertices - [imageOffset(1), imageOffset(2), imageOffset(3)];
        end
        
        % save raw images
        if p.saveRawImages || p.saveRawSubtractedImages
            image3Draw = im2double(MD.getChannel(c).loadStack(t));
            image3Draw = make3DImageVoxelsSymmetric(image3Draw, MD.pixelSize_, MD.pixelSizeZ_);
            image3Draw = addBlackBorder(image3Draw,1);
            if p.registerImages 
                image3DrawRegister = imtranslate(image3Draw, [-imageOffset(2), -imageOffset(1), -imageOffset(3)]);
                image3DrawRegister16 = uint16((2^16-1)*image3DrawRegister);
                save3DImage(image3DrawRegister16, fullfile(outFilePaths{1,c}, ['rawImageRegistered_' num2str(c) '_' num2str(t) '.tif']));
            else
                image3Draw16 = uint16((2^16-1)*image3Draw);
                save3DImage(image3Draw16, fullfile(outFilePaths{1,c}, ['rawImage_' num2str(c) '_' num2str(t) '.tif'])); 
            end
            
            % save raw subtracted images
            if t>1 && p.saveRawSubtractedImages == 1
                if p.registerImages
                    image3DrawRegisterOld = im2double(load3DImage(dataDir, ['rawImageRegistered_' num2str(c) '_' num2str(t-1) '.tif']));
                    image3Dsubtract = image3DrawRegister - image3DrawRegisterOld;
                    dataName = ['subtractedRawImage' '_' num2str(c) '_' num2str(t-1) '.mat'];
                    parsave(fullfile(outFilePaths{1,c},dataName), image3Dsubtract);
                else % if not registering images
                    image3DrawOld = im2double(MD.getChannel(c).loadStack(t-1));
                    image3DrawOld = make3DImageVoxelsSymmetric(image3DrawOld, MD.pixelSize_, MD.pixelSizeZ_);
                    image3DrawOld = addBlackBorder(image3DrawOld,1);
                    image3Dsubtract = image3Draw - image3DrawOld;
                    dataName = ['subtractedRawImage' '_' num2str(c) '_' num2str(t-1) '.mat'];
                    parsave(fullfile(outFilePaths{1,c},dataName), image3Dsubtract);
                end
            end
            
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
                
        % save the curvature as an image if desired
        if p.saveCurvatureImage == 1
            surfaceBorderOffset = surface; surfaceBorderOffset.vertices = surface.vertices+1;
            curvatureImage = makeCurvatureImage(size(imageSurface), surface, meanCurvature, neighbors);
            curvatureImage = (-1000/MD.pixelSize_)*curvatureImage;
            if p.registerImages 
                register = 'Registered'; 
            else
                register = '';
            end
            dataName = ['curvatureImage' register '_' num2str(c) '_' num2str(t) '.mat'];
            parsave(fullfile(outFilePaths{1,c},dataName), curvatureImage);
            curvatureImage(curvatureImage>=-1) = 0;
            curvature8 = uint8(-100*curvatureImage);
            save3DImage(curvature8, fullfile(outFilePaths{1,c}, ['curvature' register '8_' num2str(c) '_' num2str(t) '.tif']));
        end
        
        % save an image that includes only the pixels at the image edges if desired
        morphRadiusErode = 8;
        if p.saveEdgeImage == 1
            
            % morphologically erode the thresholded surface image
            surfaceThresh = imageSurface > intensityLevels(c,t);
            sphereErodeSE = makeSphere3D(morphRadiusErode);
            surfaceThreshErode = imerode(surfaceThresh, sphereErodeSE);
            
            % find the pixels at the edge
            edgePixels = surfaceThresh - surfaceThreshErode;
            if p.registerImages 
                edgeImage = edgePixels.*image3DrawRegister;
            else    
                edgeImage = edgePixels.*image3Draw;
            end
            
            % save the edgeImage
            if p.registerImages 
                register = 'Registered'; 
            else
                register = '';
            end
            edgeImage16 = uint16((2^16-1)*edgeImage);
            save3DImage(edgeImage16, fullfile(outFilePaths{1,c}, ['edgeImage' register '_' num2str(c) '_' num2str(t) '.tif']));
            
        end
        
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

