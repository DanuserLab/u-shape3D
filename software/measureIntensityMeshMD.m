function measureIntensityMeshMD(processOrMovieData, varargin)

% measureIntensityMeshMD - measures the mean signal intensity near the mesh
%
% (some of this process is adapted from Hunter Elliott's code)
%
%% INPUTS:
%
% MD                     - a MovieData object that will be analyzed
%
% p.OutputDirectory      - directory where the output will be saved
%
% p.chanList             - a list of the channels that will be analyzed 
%
% p.mainChannel          - the channel from which the surface is calculated, 
%                        set to 'self' to use the channel set in the channels 
%                        parameter, or set to an array with length equal to
%                        the number of channels being analyzed
%
% p.otherChannel         - the channel index for calculating the intensity 
%                        outside the cell
%
% p.sampleRadius         - the radius in microns over which the intensity
%                        is sampled
%
% p.intensityMode        - the way in which intensity is measured
%    intensityInsideRaw: measure the raw intensity inside the cell
%    intensityOtherOutsideRaw: measure the raw intensity of the other 
%                         channel outside the cell (note that useDeconvolved 
%                         and usePhotobleach are ignored for this option)
%    intensityOtherRaw: measure the raw intensity of the other 
%                         channel (note that useDeconvolved and 
%                         usePhotobleach are ignored for this option)
%    intensityInsideDepthNormal: measure the depth normalized intensity 
%                         inside the cell
%    intensityOtherInsideDepthNormal: measure the depth normalized intensity 
%                         of the other channel inside the cell
%
% p.leftRightCorrection  - 1 to subtract a left-right intensity offset, 0
%                        otherwise
%
% p.useDifImage          - 1 to analyze the diferance between the current raw 
%                          frame and the previous raw frame
%
% p.useDeconvolved       - 1 to use the deconvolved image, 0 otherwise
%
% p.usePhotobleach       - 1 to use the photobleach corrected images, 0
%                        otherwise. Note that this setting will only matter
%                        if useDeconvolved is set to 0. To control what
%                        image is deconvolved set Deconvolution process
%                        parameters.
% 
% p.meanNormalization    - 1 to use the mean value for intensity, used only
%                          for intensity at mesh vertices
% 
% p.normInsideBackground    - 1 to remove the background of the cytosol area
% 
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

[MD, process] = getOwnerAndProcess(processOrMovieData,'Intensity3DProcess',true);
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

photoDir = [MD.outputDirectory_ filesep 'Morphology' filesep 'Photobleach']; % always defined for the sake of the parfor

% verify available & valid channels - requires Mesh3DProcess completed.
p.chanList = MeshProcessingProcess.checkValidMeshChannels(process, 'Mesh3DProcess');

%% configure input paths
inFilePaths = cell(5, numel(MD.channels_));
for j = p.chanList
    inFilePaths{1,j} = photoDir;  %% TODO - check the channel output for photobleaching -process
    
    if p.useDeconvolved ~= 0 
        deconProc = MD.findProcessTag('Deconvolution3DProcess',false, false,'tag',false,'last');
        inFilePaths{2,j} = deconProc.outFilePaths_{1,j};
    end
    
    meshProc = MD.findProcessTag('Mesh3DProcess',false, false,'tag',false,'last');
    inFilePaths{3,j}= meshProc.outFilePaths_{1,j};
    inFilePaths{4,j} = meshProc.outFilePaths_{4,1}; % summary stats 
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
    mkClrDir(outFilePaths{1,i});
    if ~isfolder(outFilePaths{2,i}), mkdirRobust(outFilePaths{2,i}); end
    mkClrDir(outFilePaths{3,i});
end
process.setOutFilePaths(outFilePaths);

%% measure intensity
% display progress
disp('   Measuring intensity')

% load data that applies to all frames - Not channel specific
levels = load(fullfile(inFilePaths{4,1}, 'intensityLevels.mat'));

% generate a list of mainChannels to analyze
if ischar(p.mainChannel) && strcmp(p.mainChannel, 'self')
    p.mainChannel = p.chanList;
else
    p.mainChannel = p.mainChannel;
end

% iterate through the images
p_orig = p;
for c = p.chanList
    p = p_orig;
    p.chanList = c;
    p = splitPerChannelParams(p, c);
    
    % convert the sample radius to pixels
    sampleRadius = round(1000*p.sampleRadius/MD.pixelSize_);

    % warn the user if the sample radius is unusual
    if (sampleRadius < 3) || (sampleRadius > 50)
       warning(['The sample radius is ' num2str(sampleRadius) 'pixels. You probably do not want a very small or very large sample radius']);
    end
    
    % find the directory where the input, including surfaces are stored
    photoDir = inFilePaths{1,c};
    deconPath = inFilePaths{2,c};
    surfacePath = inFilePaths{3,c};

    parfor t = 1:1:MD.nFrames_ % parfor
        
        if p.useDifImage == 1 && t == MD.nFrames_
            continue % there is no dif image for frame 1
        end
   
        % display progress
        faceIntensities = []; % initialized for the parfor loop
        vertexIntensities = []; % initialized for the parfor loop
        disp(['      image ' num2str(t) ' (channel ' num2str(c) ')'])
        
        % set the channel defining the surface
        surfaceC = p.mainChannel(c==p.chanList);
        
        % load the image to be analyzed
        if p.useDeconvolved == 0 && p.usePhotobleach == 0
            % load the raw image
            image3D = im2double(MD.getChannel(c).loadStack(t));
        elseif p.useDeconvolved == 1 && p.usePhotobleach == 1
            % load the photobleach corrected image
            % pathDir = [MD.outputDirectory_ filesep 'Morphology' filesep 'Photobleach'];
            imageName = sprintf('photo_%d_%d.tif', c, t);
            image3D = load3DImage(photoDir, imageName); 
        elseif p.useDifImage == 1
            % load the difference image
            %difDir = [MD.outputDirectory_ filesep 'Morphology' filesep 'Mesh'];
            dataName = ['subtractedRawImage' '_' num2str(c) '_' num2str(t) '.mat'];
            difImageStruct = load(fullfile(surfacePath,dataName));
            image3D = difImageStruct.image3Dsubtract;
        else
            % load the deconvolved image
            % pathDir = [MD.outputDirectory_ filesep 'Morphology' filesep 'Deconvolution'];
            imageName = sprintf('decon_%d_%d.tif', c, t);
            image3D = load3DImage(deconPath, imageName); 
        end
        
        % load the surface
        meshName = fullfile(surfacePath, sprintf('surface_%i_%i.mat', surfaceC, t));
        sStruct = load(meshName);
        
        % load the surface image
        si = load(fullfile(surfacePath, ['imageSurface_' num2str(surfaceC) '_' num2str(t) '.mat']));
        surfaceImage = si.imageSurface;
        
        % scale the image to account for xy-z anisotropy
        image3D = make3DImageVoxelsSymmetric(image3D, MD.pixelSize_, MD.pixelSizeZ_);
        image3D = addBlackBorder(image3D,1);

        % make the masked image
        imageMasked = surfaceImage > levels.intensityLevels(surfaceC,t);
        
        % subtract the background -
        background = median(image3D(~imageMasked));
        image3D = image3D - background;
        
        % subtract the cytosol background - HMF2022
        if p.normInsideBackground ==1
            %normalize intensity to cytosolic intensity
            background = mean(image3D(imageMasked)); %it should be mean not median
            image3D = image3D ./ background;
        end
        
        % perform the left-right correction if wanted
        if p.leftRightCorrection % this function is incomplete, do not use it!
            image3D = leftRightCorrectIntensity(image3D, imageMasked);
        end
                
        % load the other channel if needed
        image3Dout = []; % for the parfor loop
        if strcmp(p.intensityMode, 'intensityOtherOutsideRaw') || ...
            strcmp(p.intensityMode, 'intensityOtherRaw') || ...
            strcmp(p.intensityMode, 'intensityOtherInsideDepthNormal')
            
            % load the raw outside channel
            image3Dout = im2double(MD.getChannel(p.otherChannel).loadStack(t));
            
            % scale the image
            image3Dout = make3DImageVoxelsSymmetric(image3Dout, MD.pixelSize_, MD.pixelSizeZ_);
            image3Dout = addBlackBorder(image3Dout,1);
            
            % subtract the background
            background = median(image3Dout(~imageMasked));
            image3Dout = image3Dout - background;
        end
        
        % measure intensity
        switch p.intensityMode
            case 'intensityInsideRaw'
                
                % measure the intensity near each face inside the cell
                image3D(image3D < 0) = 0;
                image3D(~imageMasked) = 0;
                faceIntensities = measureIntensity(image3D, sStruct.surface, sampleRadius);    
            case 'intensityInsideRawVertex'
                
                % measure the intensity near each vertex inside the
                % cell-HMF2022
                image3D(image3D < 0) = 0;
                image3D(~imageMasked) = 0;
                vertexIntensities=measureIntenistyVertex(image3D,sStruct.surface,sampleRadius);
            case 'intensityOtherOutsideRaw'
                
                % measure the intensity of the other channel near each face and only outside the cell
                image3Dout(image3Dout < 0) = 0;
                image3Dout(imageMasked) = 0;
                faceIntensities = measureIntensity(image3Dout, sStruct.surface, sampleRadius);  
                
            case 'intensityOtherRaw'
                
                % measure the intensity of the other channel near each face
                image3Dout(image3Dout < 0) = 0;
                faceIntensities = measureIntensity(image3Dout, sStruct.surface, sampleRadius);
                
            case 'intensityInsideDepthNormal'
                
                % depth normalize the image
                image3D = depthNormalize(image3D, imageMasked);
                image3D(image3D<0) = 0;
                
                % measure the intensity near each face
                faceIntensities = measureIntensity(image3D, sStruct.surface, sampleRadius);
            
                case 'intensityInsideDepthNormalVertex'%depthNormal for vertex-HMF2022
                % depth normalize the image
                image3D = depthNormalize(image3D, imageMasked);
                image3D(image3D<0) = 0;
                % measure the intensity near each vertex cell
                vertexIntensities=measureIntenistyVertex(image3D,sStruct.surface,sampleRadius);

            case 'intensityOtherInsideDepthNormal'
                
                % depth normalize the image
                image3Dout = depthNormalize(image3Dout, imageMasked);
                image3Dout(image3Dout<0) = 0;
                
                % measure the intensity near each face
                faceIntensities = measureIntensity(image3Dout, sStruct.surface, sampleRadius);
                
        end
        % normalize the intensities by the mean face intensity
        % make this part flagable -HMF2022
        if p.meanNormalization==1 && strcmp(p.intensityMode,'intensityInsideRawVertex')==1
                vertexIntensities.mean = vertexIntensities.mean./(mean(vertexIntensities.mean));
        elseif p.meanNormalization==1 && strcmp(p.intensityMode,'intensityInsideDepthNormalVertex')==1
                vertexIntensities.mean = vertexIntensities.mean./(mean(vertexIntensities.mean));
        elseif p.meanNormalization
            faceIntensities.mean = faceIntensities.mean./(mean(faceIntensities.mean));        
        end
        
        % save the intensity data 
        dataName = ['intensity_' num2str(c) '_' num2str(t) '.mat'];
        parsave(fullfile(outFilePaths{1,c}, dataName), faceIntensities); % (not a built-in function)
        if strcmp(p.intensityMode,'intensityInsideRawVertex') || strcmp(p.intensityMode,'intensityInsideDepthNormalVertex') %save the intensity on vertex - HMF2022
               parsave(fullfile(outFilePaths{1,c}, dataName), vertexIntensities); % (not a built-in function)
        end 
        %HMF update it
        if strcmp(p.intensityMode,'intensityInsideRawVertex')==1 || strcmp(p.intensityMode,'intensityInsideDepthNormalVertex')==1
            [m, h] = plotMeshMD(MD,'surfaceMode','intensityVertex');
        else 
            [m, h] = plotMeshMD(MD,'surfaceMode','intensity');
        end 
    savefig(h, fullfile(outFilePaths{3,c},'meshIntensity.fig'))
    end
end

% save parameters 
save(fullfile(outFilePaths{2,1}, 'intensityParameters.mat'), 'p');


%%% old code which may one day be of interest   
%
%         % create a voxelated image from the mesh
%         gridX = 1:1:MD.imSize_(1);
%         gridY = 1:1:MD.imSize_(2);
%         gridZ = 1:1:MD.zSize_;
%         imageMasked = im2double(VOXELISE(gridX,gridY,gridZ,sStruct.surface)); % Note that VOXELISE is quite buggy
%         imageMasked = imfill(imageMasked, 'holes');
%         imageMasked = permute(imageMasked, [2 1 3]); % remember the xy-z size scale dif.
%
%               
%                 % smooth the image
%                 image3D = filterGauss3D(image3D, 4);
%               
%                 % deconvolve the image
%                 weiner = 0.01; imageSize = size(image3D); filterSize = max(imageSize)+1;
%                 [x,y,z] = ndgrid(-filterSize:filterSize,-filterSize:filterSize,-filterSize:filterSize);
%                 PSF = exp(-(x.*x/(2*4^2)+y.*y/(2*1^2)+z.*z/(2*1^2)));
%                 PSF = PSF./sum(PSF(:));
%                 OTF = calculateSmallOTF(PSF, imageSize);
%                 
%                 image3D = fftshift(fftn(image3D));
%                 image3D = image3D.*OTF./((OTF.*OTF) + weiner);
%                 image3D = ifftn(ifftshift(image3D));
%                 image3D = abs(image3D);
%                 image3D = image3D.*(image3D > 0);
% 
%                 % remake the mesh
%                 [surface, surfaceImage, level] = meshOtsu(image3D);
%                 image3D = addBlackBorder(image3D,1);
%                 
%                 % depth normalize the image
%                 imageMask = surfaceImage > level;
%                 imageMasked = surfaceImage > levels.intensityLevels(c,t);
%                 image3D = image3D - background;
%
