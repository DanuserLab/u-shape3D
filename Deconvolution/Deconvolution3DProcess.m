classdef Deconvolution3DProcess < ImageProcessingProcess
    
    methods (Access = public)
        function obj = Deconvolution3DProcess(owner, varargin)
            % obj = obj@Process(owner, Deconvolution3DProcess.getName);
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
            
            if nargin == 0
                super_args = {};
            else
                % Input check
                ip = inputParser;
                ip.CaseSensitive = false;
                ip.KeepUnmatched = true;
                ip.addRequired('owner',@(x) isa(x,'MovieData'));
                ip.addOptional('outputDir', owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;

                super_args{1} = owner;
                super_args{2} = Deconvolution3DProcess.getName;
                super_args{3} = @deconvolveMovieMD;
                if isempty(funParams)
                    funParams = Deconvolution3DProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
            end            
            obj = obj@ImageProcessingProcess(super_args{:});
            
            % obj.funName_ = @deconvolveMovieMD;
            % obj.funParams_ = Deconvolution3DProcess.getDefaultParams(owner);
            obj.is3Dcompatible_ = true;
        end
                
        function checkParameters(obj, owner, params)
            
            % check that the parameters inputted are valid
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.StructExpand = true;
            addParameter(ip,'deconMode',@ischar);
            addParameter(ip,'weinerAuto',@(x) (x==0 || x==1));
            addParameter(ip,'weiner',@(x) (isnumeric(x) && isscaler(x) && x>=0));
            addParameter(ip,'apoHeight',@(x) (isnumeric(x) && isscaler(x) && x>=0 && x<=1));
            addParameter(ip,'richLucyIter',@(x) (isscaler(x) && x>=0 && mod(x,1)==0));
            addParameter(ip,'pathPSF',@ischar);
            addParameter(ip,'usePhotobleach',@(x) (x==0 || x==1));
            addParameter(ip,'channels',@(x) ~isempty(x));
            addParameter(ip,'OutputDirectory',@ischar);
            ip.parse(params);
            paramsMatched = ip.Results;
            paramsUnmatched = ip.Unmatched;
            
            % check the meshMode parameter
            deconModes = {'weiner', 'richLucy'};
            assert(max(cellfun(@(x) strcmp(x,paramsMatched.deconMode), deconModes)), '%s is an invalid deconMode parameter', paramsMatched.deconMode);
                        
            % check the channels parameter
            channelAll = ischar(paramsMatched.channels) && strcmp(paramsMatched.channels, 'all');
            channelNumeric = isnumeric(paramsMatched.channels) && min(ismember(paramsMatched.channels, 1:length(owner.channels_)));
            assert(channelAll | channelNumeric, 'The channels parameter is invalid.')
            
            % warn the user about unidentified parameters
            if ~isempty(paramsUnmatched)
                names = fieldnames(paramsUnmatched);
                for s = 1:length(names)
                    warning('MATLAB:unusedParam', ['Invalid deconvolution parameter: ' names{s}]);
                end
            end
            
            % check that all parameters defined in defaultParams are defined here
            namesDefaultParams = fieldnames(obj.getDefaultParams(owner));
            namesParams = fieldnames(paramsMatched);
            assert(isequal(sort(namesDefaultParams), sort(namesParams)), 'Some parameters for the Deconvolution process are missing.'); 
        end
        
        function h = draw(obj, iChan, iFrame, iZ, varargin)
            % Function to draw process output
            outputList = obj.getDrawableOutput();  
                               
            ip = inputParser;
            ip.addRequired('obj',@(x) isa(x,'Process'));
            ip.addRequired('iChan', @isnumeric);
            ip.addRequired('iFrame', @isnumeric);
            ip.addRequired('iZ', @(x) ismember(x,1:obj.owner_.zSize_));
            ip.addParameter('output', [], @(x) all(ismember(x,{outputList.var})));
            ip.KeepUnmatched = true;
            ip.parse(obj, iChan, iFrame, iZ, varargin{:});

            iChan = ip.Results.iChan;
            iZ = ip.Results.iZ;
            iOutput = find(cellfun(@(y) isequal(ip.Results.output,y),{outputList.var}));
            
            % Initialize display method
            if isempty(obj.getDisplayMethod(iOutput,iChan))
                obj.setDisplayMethod(iOutput, iChan,...
                    outputList(iOutput).defaultDisplayMethod(iChan));
            end

            imData = obj.loadChannelOutput(iChan,iFrame,iZ);
            data = zeros(size(imData,1),size(imData,2), size(imData,3));
            data(:,:,1) = outputList(iOutput).formatData(imData);
            
            tag = ['process' num2str(obj.getIndex()) ip.Results.output 'Output'];
            h = obj.displayMethod_{iOutput, 1}.draw(data, tag, ip.Unmatched);

        end
       
        function setParameters(obj, params, varargin)
            % overloaded method to conform Meghan's channel parameter to standard naming convention for GUI and API
            if isfield(params, 'channels')
                if ischar(params.channels) && strcmp('all', params.channels)
                    params.ChannelIndex = 1:numel(obj.owner_.channels_);
                elseif isnumeric(params.channels)
                    params.ChannelIndex = params.channels;
                end
            end
            obj.setParameters@Process(params, varargin{:});
        end
        
        function setPara(obj, params, varargin)
            obj.setParameters(params, varargin{:});
        end
    end
 
    methods (Static)
        function name = getName()
            name = 'Deconvolution';
        end
        
        function h = GUI()
            % try 
                h = @deconvolution3DProcessGUI;
            % catch
%                 warning('Process GUI Failed to load -- defaulting to Command Line Parameter GUI input');
                % h = @cliGUI;
            % end
        end        
        
        function output = getDrawableOutput(varargin)
            n = 1;
            output(n).name = 'Deconvolution';
            output(n).var = 'deconVar';
            output(n).formatData = @mat2gray;
            output(n).defaultDisplayMethod = @ImageDisplay;
            output(n).type = 'image';
        end

        function defaultParams = getDefaultParams(owner, varargin)
            
            % check inputs
            ip = inputParser;
            ip.addRequired('owner', @(x) isa(x, 'MovieObject'));
            ip.addOptional('outputDir', owner.outputDirectory_, @ischar);
            ip.parse(owner);
                        
            % Also see defaultParamsDeconvolveProcess.m - set default parameters for the Deconvolve process
            nChan = numel(owner.channels_);
            defaultParams = struct();
            defaultParams.channels = ''; % the channels to deconvolve, set to 'all' for all the channels or give an array of channel numbers
            defaultParams.InputImageProcessIndex = []; % TODO -- Process Output to use as input to the deconvolution, empty implies raw images
            defaultParams.deconMode = {'weiner'}; % the deconvolution type ('weiner', or 'richLucy')
            defaultParams.weinerAuto = 0; % set to 1 to automatically determine the Weiner parameter (should only be used for uniformly bright objects)
            defaultParams.weiner = 0.018; % the Weiner parameter, only used if weinerAuto is set to 0
            defaultParams.apoHeight = 0.06; % the apodization height
            defaultParams.richLucyIter = 10; % the number of Richardson Lucy deconvolution iterations
            defaultParams.pathPSF = [];
            defaultParams.usePhotobleach = 0; % set to 1 to load photobleach corrected movies            
            % defaultParams.computeMIP = true; % compute MIP of deconvolved movie (deprecated option - no included directly in package)
            defaultParams.ChannelIndex = 1:numel(owner.channels_); % see class method setPara above
            % set more default parameters
            defaultParams.OutputDirectory = fullfile(ip.Results.outputDir,'Morphology','Deconvolution');        
            
            % list of parameters which can be specified at a per-channel
            % level. If specified as scalar these will  be replicated
            
            defaultParams.PerChannelParams = {'deconMode','weinerAuto','weiner','apoHeight','richLucyIter','usePhotobleach'};
            defaultParams = prepPerChannelParams(defaultParams, nChan);
        end
    end
end
