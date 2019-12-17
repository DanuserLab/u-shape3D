classdef Check3DCellSegmentationProcess < MaskProcess & NonSingularProcess
%Check3DCellSegmentationProcess - create and display binary 3D mask using Mesh3DProcess outputs.
% Calls the wrapped function: saveThresholdedImageAsTifMD.m
% Mesh3DProcess is part of the Morphology3DPackage.    
% also see: saveThresholdedImageAsTifMD.m, Mesh3DProcess.m
% Andrew R. Jamieson, July 2018
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

    methods (Access = public)
        function obj = Check3DCellSegmentationProcess(owner,varargin)
            if nargin == 0
                super_args = {};
            else
                % Input check
                ip = inputParser;
                ip.addRequired('owner',@(x) isa(x,'MovieData'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;
                
                % Define arguments for superclass constructor
                super_args{1} = owner;
                super_args{2} = Check3DCellSegmentationProcess.getName;
                super_args{3} = @Check3DCellSegmentationProcess.saveThresholdedImageAsTifMD_andMIP;
                if isempty(funParams)
                    funParams = Check3DCellSegmentationProcess.getDefaultParams(owner, outputDir);
                end
                super_args{4} = funParams;
            end
            obj = obj@MaskProcess(super_args{:});
            obj.is3Dcompatible_ = true; 
        end 
        function mask = loadChannelOutput(obj, iChan, iFrame, varargin)
            % Input check
            ip =inputParser;
            ip.addRequired('obj');
            ip.addRequired('iChan', @obj.checkChanNum);
            ip.addRequired('iFrame', @obj.checkFrameNum);
            ip.addParameter('iZ',[], @(x) ismember(x,1:obj.owner_.zSize_));
            ip.addParameter('projectionAxis3D','Z', @(x) ismember(x,{'Z','X','Y','three'}));
            ip.addParameter('output',[],@ischar);
            ip.addParameter('useCache',true,@islogical);
            ip.parse(obj,iChan,iFrame,varargin{:})
            p = ip.Results;
            
            imFile = [obj.outFilePaths_{1, p.iChan} filesep ['thresholdMask_' num2str(p.iChan) '_' num2str(p.iFrame) '.tif']];

            % 
            % mask = imread(imFile, p.iZ+1);
            % mask = imtranslate(mask,[-1, -1]);

%             s = cached.load(tif3Dread([obj.outFilePaths_{1, p.iChan} ... 
%                             filesep ['thresholdMask_' num2str(p.iChan) '_' num2str(p.iFrame) '.tif']]), ...
%                              '-useCache',  p.useCache, 'stack3D');

            stack3D = tif3Dread([obj.outFilePaths_{1, p.iChan} ... 
                                filesep ['thresholdMask_' num2str(p.iChan) '_' num2str(p.iFrame) '.tif']]);
            
            %% WIP - fix volume size change issue?
            zp = floor((size(stack3D,3)-obj.owner_.zSize_)/2)+1;
            xyp = floor((size(stack3D,1)-obj.owner_.imSize_(1))/2);
            mask = stack3D(xyp:(size(stack3D,1)-xyp),xyp:(size(stack3D,2)-xyp),zp:(size(stack3D,3)-zp));
            
            mask = mask(:, :, p.iZ+1);
%             mask = stack3D(:,:,p.iZ-zp);
        end
        
        function h = draw(obj,iChan,varargin)
            
            h = obj.draw@MaskProcess(iChan,varargin{:},'useCache',true);
        
        end

%         function output = getDrawableOutput(obj)
%             output = getDrawableOutput@DetectionProcess(obj);
%             output(1).name='Detected Objects by zSlice';
%             output(1).var = 'detect3D';
%             output(1).formatData=@DetectionProcess.formatOutput3D;
%             
%             output(2) = getDrawableOutput@DetectionProcess(obj);
%             output(2).name='Detected Objects';
%             output(2).var = 'detect3Dall';
%             output(2).formatData=@DetectionProcess.formatOutput3D;
%         end
    end
    
    methods (Static)
        function name = getName()
            name = 'CheckCellSegmentation';
        end
        
        function h = GUI()
            h = @noSettingsProcessGUI;
            % h = @cliGUI
        end
        
        function defaultParams = getDefaultParams(owner,varargin)
            % check inputs
            ip = inputParser;
            ip.addRequired('owner', @(x) isa(x, 'MovieObject'));
            ip.addOptional('outputDir', owner.outputDirectory_, @ischar);
            ip.parse(owner)

            nChan = numel(owner.channels_);
            defaultParams = struct();                        
        
            defaultParams.ChannelIndex = 1:numel(owner.channels_); % see class method setPara above
            % set more default parameters
            defaultParams.OutputDirectory = fullfile(ip.Results.outputDir,'Morphology', 'Analysis','Threshold');        
            defaultParams = prepPerChannelParams(defaultParams, nChan);                    
        end

        function saveThresholdedImageAsTifMD_andMIP(processOrMovieData, varargin)
            %saveThresholdedImageAsTifMD - create binary 3D mask using Mesh3DProcess outputs.
            % saveThresholdedImageAsTifMD should be called by Check3DCellSegmentationProcess.
            % Mesh3DProcess is part of the Morphology3DPackage. 
            % Andrew R. Jamieson (modified from Meghan Driscoll) July 2018

            % saveSurfaceImageAsTif - just what it sounds like
            ip = inputParser;
            ip.CaseSensitive = false;
            ip.addRequired('processOrMovieData', @(x) isa(x,'Process') && isa(x.getOwner(),'MovieData') || isa(x,'MovieData'));
            ip.addOptional('paramsIn',[], @isstruct);
            ip.parse(processOrMovieData,varargin{:});
            paramsIn = ip.Results.paramsIn;

            [MD, thisProc] = getOwnerAndProcess(processOrMovieData,'Check3DCellSegmentationProcess',true);
            p = parseProcessParams(thisProc, paramsIn);

            meshProc = MD.findProcessTag('Mesh3DProcess',false, false,'tag',false,'last');

            % verify available & valid channels - requires Mesh3DProcess completed.
            p.ChannelIndex = MeshProcessingProcess.checkValidMeshChannels(thisProc, 'Mesh3DProcess');

            % ============= Configure InputPaths. ================
            inFilePaths = cell(1, numel(MD.channels_));
            for j = p.ChannelIndex
                inFilePaths{1,j} = meshProc.outFilePaths_{4,1}; %(surfacePathIntensity)
                inFilePaths{2,j} = meshProc.outFilePaths_{1,j}; %(surfacePath)
            end
            thisProc.setInFilePaths(inFilePaths);
            % ============= ======================================

            % ============= Configure OutputPaths. ================
            dataDir = p.OutputDirectory;
            outFilePaths = cell(3, numel(MD.channels_));
            for i = p.ChannelIndex    
                outFilePaths{1,i} = [dataDir filesep 'ch' num2str(i)];
                mkClrDir(outFilePaths{1,i});
            end
            thisProc.setOutFilePaths(outFilePaths);
            % ====================================================

            % load the Otsu thresholds (one file for all channels)
            levels = load(fullfile(inFilePaths{1,1}, 'intensityLevels.mat')); %(surfacePathIntensity)

            % iterate through channels
            for c = p.ChannelIndex
                % iterate through the frames
                for t = 1:MD.nFrames_   
                        % load the surface image
                        si = load(fullfile(inFilePaths{2,c}, ['imageSurface_' num2str(c) '_' num2str(t) '.mat'])); %(surfacePath)
                        surfaceImage = si.imageSurface;
                        
                        % make the thresholded image
                        thresholdedImage = surfaceImage > levels.intensityLevels(c,t);
                        thresholdedImage = uint16((2^16-1)*thresholdedImage);
                        
                        % save the surface image
                        imagePath = fullfile(outFilePaths{1,c}, ['thresholdMask_' num2str(c) '_' num2str(t) '.tif']);
                        save3DImage(thresholdedImage, imagePath);
                end
            end        
        end
    end
end
