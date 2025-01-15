function measureMeshMotionMD(processOrMovieData, varargin)

% measureMeshMotionMD - measures the motion of the mesh from frame to frame
%
%% INPUTS:
%
% MD                     - a MovieData object that will be analyzed
%
% p.OutputDirectory      - directory where the output will be saved
%
% p.chanList             - a list of the channels that will be analyzed 
%
% p.numNearestNeighbors  - the number of nearest neighbors to take the median over in the motion analysis
%
% p.motionMode           - the way in which motion is measured
%    'backwards': finds the distance between each face and the closest face in the previous frame
%    'forwards': finds the distance between each face and the closest face in the next frame
%    'backwardsForwards': finds the backwards and forwards motions, saves backwards as the "motion" 
%
% p.registerImages       - set to 1 to register adjacent frames, 0 otherwise
%
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

[MD, process] = getOwnerAndProcess(processOrMovieData,'MeshMotion3DProcess',true);
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

%% configure input paths.
inFilePaths = cell(2, numel(MD.channels_));
for j = p.chanList
    meshProc = MD.findProcessTag('Mesh3DProcess',false, false,'tag',false,'last');
    inFilePaths{1,j}= meshProc.outFilePaths_{1,j};
    deconProc = MD.findProcessTag('Deconvolution3DProcess',false, false,'tag',false,'last');
    inFilePaths{2,j}= deconProc.outFilePaths_{1,j}; 
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
    mkClrDir(outFilePaths{1,i});
    if ~isfolder(outFilePaths{2,i}), mkdirRobust(outFilePaths{2,i}); end
    mkClrDir(outFilePaths{3,i});
end
outFilePaths{4,1} = dataDir;
process.setOutFilePaths(outFilePaths);

%% measure mesh motion
disp('   Measuring mesh motion')
% setup the image registration configuration
if p.registerImages == 1
    [optimizer, metric] = imregconfig('monomodal');
    regMode = 'translation';
end

% iterate through the images
p_orig = p;
for c = p.chanList
    p = p_orig;
    p.chanList = c;
    p = splitPerChannelParams(p, c);
    
    % find the directory where the surfaces and deconvolved images are stored
    meshPath = fullfile(inFilePaths{1,c},'surface_%i_%i.mat');
    deconPath = fullfile(inFilePaths{2,c});
%     deconName = 'decon_%i_%i.tif';

    for t = 1:MD.nFrames_  
        
        % display progress
        disp(['      image ' num2str(t) ' (channel ' num2str(c) ')'])
        meshPath = fullfile(inFilePaths{1,c},sprintf('surface_%i_%i.mat', c, t));
        
        % load the surface data
        sNew = load(meshPath);

        % load and resize the deconvolved image
        if p.registerImages == 1
            image3Dnew = im2double(load3DImage(fullfile(deconPath, sprintf('decon_%i_%i.tif', c, t))));
            image3Dnew = addBlackBorder(image3Dnew,1);
            image3Dnew = make3DImageVoxelsSymmetric(image3Dnew, MD.pixelSize_, MD.pixelSizeZ_);
            image3Dnew = uint16((2^16-1)*image3Dnew);
        end
        
        % don't try to measure motion if this is the first frame
        if t == 1
            
            % make and save a dummy motion
            motion = NaN(1,size(sNew.surface.faces,1));
            parsave(fullfile(outFilePaths{1,c},['motion_' num2str(c) '_' num2str(t) '.mat']), motion);
            
        else
            % register the images if requested
            if p.registerImages == 1
                
                % register the two images  (this type of registration works best for images that change little from frame to frame)
                tform = imregtform(image3Dnew, image3Dold, regMode, optimizer, metric);
                
                % transform the new mesh
                newVertices = NaN(size(sNew.surface.vertices, 1),3);
                for v = 1:size(sNew.surface.vertices,1)
                    newV = [sNew.surface.vertices(v,:), 1]*tform.T;
                    newVertices(v,:) = newV(1:3);
                end
                sNew.surface.vertices = newVertices;

            end
            
            % measure and save mesh motion
            switch p.motionMode
                case 'backwards'
                    motion = measureMeshMotionNearest(sNew.surface, sOld.surface, p.numNearestNeighbors);
                    parsave(fullfile(outFilePaths{1,c},['motion_' num2str(c) '_' num2str(t) '.mat']), motion);
                    
                case 'forwards'
                    motion = measureMeshMotionNearest(sOld.surface, sNew.surface, p.numNearestNeighbors);
                    parsave(fullfile(outFilePaths{1,c},['motion_' num2str(c) '_' num2str(t-1) '.mat']), motion);
                    
                case 'backwardsForwards'
                    motion = measureMeshMotionNearest(sNew.surface, sOld.surface, p.numNearestNeighbors);
                    parsave(fullfile(outFilePaths{1,c},['motion_' num2str(c) '_' num2str(t) '.mat']), motion);
                    motionForwards = measureMeshMotionNearest(sOld.surface, sNew.surface, p.numNearestNeighbors);
                    parsave(fullfile(outFilePaths{1,c},['motionForwards_' num2str(c) '_' num2str(t-1) '.mat']), motionForwards);
            end
            
        end
        
        % make a dummy motion for the last frame if needed
        if t == MD.nFrames_ 
            switch p.motionMode   
                case 'forwards'
                    motion = NaN(1,size(sNew.surface.faces,1));
                    parsave(fullfile(outFilePaths{1,c},['motion_' num2str(c) '_' num2str(t) '.mat']), motion);
                    
                case 'backwardsForwards' 
                    motionForwards = NaN(1,size(sNew.surface.faces,1));
                    parsave(fullfile(outFilePaths{1,c},['motionForwards_' num2str(c) '_' num2str(t) '.mat']), motionForwards);
            end
        end
        % reset data for the next frame
        sOld = sNew;
        if p.registerImages == 1, image3Dold = image3Dnew; end
        
    end
    if MD.nFrames_ > 1
        [m, h] = plotMeshMD(MD,'surfaceMode','motion');
    else
        m = [];
        h = m;
    end
    if isempty(m) 
        close(h);
    else
        savefig(h, fullfile(outFilePaths{3,c},'motion.fig'))         
    end
    
end

% save parameters 
save(fullfile(outFilePaths{2,1},'meshMotionParameters.mat'), 'p');
