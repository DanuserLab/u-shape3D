classdef Intensity3DProcess < MeshProcessingProcess

% Intensity3D - 
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
    
    methods (Access = public)
        function obj = Intensity3DProcess(owner, varargin)
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
                super_args{2} = Intensity3DProcess.getName;
                super_args{3} = @measureIntensityMeshMD;
                if isempty(funParams)
                    funParams = Intensity3DProcess.getDefaultParams(owner, outputDir);
                end
                super_args{4} = funParams;
            end
            obj = obj@MeshProcessingProcess(super_args{:});
            obj.is3Dcompatible_ = false;             
        end
        function checkParameters(obj, owner, params)
            
            % check that the parameters inputted are valid
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.StructExpand = true;
            addParameter(ip,'sampleRadius',@(x) (isscaler(x) && x>=0));
            addParameter(ip,'intensityMode',@(x) (ischar(x)));
            addParameter(ip,'useDeconvolved',@(x) x==0 || x==1);
            addParameter(ip,'usePhotobleach',@(x) x==0 || x==1);
			addParameter(ip,'leftRightCorrection',@(x) x==0 || x==1);
            addParameter(ip,'useDifImage',@(x) x==0 || x==1);
            addParameter(ip,'otherChannel',@(x) (isscaler(x) && x>=0 && mod(x,1)==0));
            addParameter(ip,'mainChannel',@(x) ~isempty(x));
            addParameter(ip,'channels',@(x) ~isempty(x));
            addParameter(ip,'OutputDirectory',@ischar);
            addParameter(ip,'ChannelIndex',@isnumeric);
            addParameter(ip,'PerChannelParams',@iscell);
            addParameter(ip,'InputImageProcessIndex',@(x) isempty(x) || isnumeric(x));            
            ip.parse(params);
            paramsMatched = ip.Results;
            paramsUnmatched = ip.Unmatched;
            
            % check the intensityMode parameter
            intensityModes = {'intensityInsideDepthNormal', 'intensityInsideRaw', 'intensityOtherOutsideRaw', 'intensityOtherRaw', 'intensityOtherInsideDepthNormal'};
            assert(max(cellfun(@(x) strcmp(x,paramsMatched.intensityMode), intensityModes)), '%s is an invalid intensityMode parameter', paramsMatched.intensityMode);
            
            % check the channels parameter
            channelAll = ischar(paramsMatched.channels) && strcmp(paramsMatched.channels, 'all');
            channelNumeric = isnumeric(paramsMatched.channels) && min(ismember(paramsMatched.channels, 1:length(owner.channels_)));
            assert(channelAll | channelNumeric, 'The channels parameter is invalid.')
            
            % check the mainChannel parameter
            channelSelf = ischar(paramsMatched.mainChannel) && strcmp(paramsMatched.mainChannel, 'self');
            channelNumeric = isnumeric(paramsMatched.mainChannel) && min(ismember(paramsMatched.mainChannel, 1:length(owner.channels_)));
            assert(channelSelf | channelNumeric, 'The mainChannel parameter is invalid.')
                        
            % warn the user about unidentified parameters
            if ~isempty(paramsUnmatched)
                names = fieldnames(paramsUnmatched);
                for s = 1:length(names)
                    warning('MATLAB:unusedParam', ['Invalid intensity parameter: ' names{s}]);
                end
            end
            
            % check that all parameters defined in defaultParams are defined here
            namesDefaultParams = fieldnames(obj.getDefaultParams(owner));
            namesParams = fieldnames(paramsMatched);
            assert(isequal(sort(namesDefaultParams), sort(namesParams)), 'Some parameters for the Intensity process are missing.'); 
        end
        function output = getDrawableOutput(obj, varargin)
            % TODO - make fancy method for selected frame to render.
            % for now default to first frame.
            validChans = find(obj.checkChannelOutput);
            n = 0; 
            for iCh = validChans
                n = n + 1;
                output(n).name = ['Intensity Rendering'];
                output(n).var = 'intensity';
                output(n).formatData = [];
                output(n).type = 'graph';
                output(n).defaultDisplayMethod = @(x)FigDisplay('plotFunc', @plotMeshMDWrapper,...
                                            'plotFunParams', {'surfaceMode', 'intensity','iChan', iCh});
            end
        end          
    end
    
    methods (Static)
        function name = getName()
            name = 'Intensity';
        end
        
        function h = GUI()
            h = @Intensity3DProcessGUI;
            % h = @cliGUI;
        end

        function defaultParams = getDefaultParams(owner, varargin)
            
            % check inputs
            ip = inputParser;
            ip.addRequired('owner', @(x) isa(x, 'MovieObject'));
            ip.addOptional('outputDir', owner.outputDirectory_, @ischar);
            ip.parse(owner)
                        
            % find default parameters
            nChan = numel(owner.channels_);
            defaultParams = struct();  
 
            defaultParams.otherChannel = 2; % channel index for calculating the intensity outside the cell
            defaultParams.sampleRadius = 2; % the radius in microns over which the intensity is sampled
            defaultParams.intensityMode = {'intensityInsideDepthNormal'}; % modes: 'intensityInsideDepthNormal', 'intensityInsideRaw', 'intensityOtherInsideDepthNormal', 'intensityOtherOutsideRaw', intensityOtherRaw' 
defaultParams.leftRightCorrection = 0; % try to corrects the left-right microscopy intensity offset
            defaultParams.useDifImage = 0; % analyzes the difference between two frames
            defaultParams.useDeconvolved = 0; % 1 to use the deconvolved image, 0 otherwise
            defaultParams.usePhotobleach = 0; % 1 to use the photobleach corrected images, 0 otherwise            
            
            defaultParams.PerChannelParams = fieldnames(defaultParams);
            
            defaultParams.mainChannel = 'self'; % the channel from which the surface is drawn, set to 'self' to use the channel set in the channels parameter, or set to an array the length of the number of channels to analyze
            defaultParams.ChannelIndex = 1:numel(owner.channels_); % see class method setPara above
            defaultParams.channels = ''; % the channels to mesh, set to 'all' for all the channels or give an array of channel numbers
            defaultParams.InputImageProcessIndex = []; % TODO -- Process Output to use as input to the deconvolution, empty implies raw images

            % Edit results folder orgnization if this process is used in uSignal3DPackage, Qiongjing (Jenny) Zou, July 2023
            if ~isempty(ip.Results.owner.packages_) && isa(ip.Results.owner.packages_{end}, 'uSignal3DPackage')
                defaultParams.OutputDirectory = [ip.Results.outputDir filesep 'uSignal3DPackage' filesep 'Intensity'];
            else
                defaultParams.OutputDirectory = fullfile(ip.Results.outputDir,'Morphology','Analysis','Intensity');   
            end
                   
            defaultParams = prepPerChannelParams(defaultParams, nChan);                      
        
            defaultParams.rmInsideBackground = 1; % 1 is to subtract the background. New parameter added for Hanieh Mazloom Farsibaf in measureIntensityMeshMD, June 2022.
            defaultParams.meanNormalization = 1; % New parameter added for Hanieh Mazloom Farsibaf in measureIntensityMeshMD, June 2022.
            
        end
        
    end
end
