classdef IntensityMotifCompare3DProcess < MeshProcessingProcess
    
    methods (Access = public)
        function obj = IntensityMotifCompare3DProcess(owner, varargin)
            if nargin == 0
                super_args = {};
            else
                % Input check
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
                ip.addRequired('owner',@(x) isa(x,'MovieData'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;
                
                % Define arguments for superclass constructor
                super_args{1} = owner;
                super_args{2} = IntensityMotifCompare3DProcess.getName;
                super_args{3} = @measureIntensityBlebCompareMeshMD;
                if isempty(funParams)
                    funParams = IntensityMotifCompare3DProcess.getDefaultParams(owner, outputDir);
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
            addParameter(ip,'analyzeOnlyFirst',@(x) x==0 || x==1);
            addParameter(ip,'analyzeOtherChannel',@(x) x==0 || x==1);
            addParameter(ip,'analyzeForwardsMotion',@(x) x==0 || x==1);
            addParameter(ip,'calculateVonMises',@(x) x==0 || x==1);
            addParameter(ip,'calculateProtrusionDiffusion',@(x) x==0 || x==1);
            addParameter(ip,'numDiffusionIterations',@(x) (isscaler(x) && x>=0 && isinteger(x)));
            addParameter(ip,'calculateDistanceTransformProtrusions',@(x) x==0 || x==1);
            addParameter(ip,'channels',@(x) ~isempty(x));
            addParameter(ip,'OutputDirectory',@ischar);
            addParameter(ip,'ChannelIndex',@isnumeric);
            addParameter(ip,'PerChannelParams',@iscell);
            addParameter(ip,'InputImageProcessIndex',@(x) isempty(x) || isnumeric(x));                        
            ip.parse(params);
            paramsMatched = ip.Results;
            paramsUnmatched = ip.Unmatched;
 
            % check the channels parameter
            channelAll = ischar(paramsMatched.channels) && strcmp(paramsMatched.channels, 'all');
            channelNumeric = isnumeric(paramsMatched.channels) && min(ismember(paramsMatched.channels, 1:length(owner.channels_)));
            assert(channelAll | channelNumeric, 'The channels parameter is invalid.')
                        
            % warn the user about unidentified parameters
            if ~isempty(paramsUnmatched)
                names = fieldnames(paramsUnmatched);
                for s = 1:length(names)
                    warning('MATLAB:unusedParam', ['Invalid intensityBlebCompare parameter: ' names{s}]);
                end
            end
            
            % check that all parameters defined in defaultParams are defined here
            namesDefaultParams = fieldnames(obj.getDefaultParams(owner));
            namesParams = fieldnames(paramsMatched);
            assert(isequal(sort(namesDefaultParams), sort(namesParams)), 'Some parameters for the IntensityBlebCompare process are missing.'); 
        end
        
    end
    
    methods (Static)
        function name = getName()
            name = 'IntensityMotifCompare';
        end

        function h = GUI()
            h = @IntensityMotifCompare3DProcessGUI;
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
                        
            % find default parameters
            
            defaultParams.PerChannelParams = fieldnames(defaultParams);
            defaultParams.analyzeOnlyFirst = 0; % set to true to analyze only the first frame in each series
            defaultParams.analyzeOtherChannel = 0; % set to true to analyze the intensity in the other channel too
            defaultParams.analyzeForwardsMotion = 0; % set to true to analyze the forwards motion as well as the regular motion
            defaultParams.calculateVonMises = 0; % set to true to calculate the von Mises-Fisher parameter for protrusions in various ways 
            defaultParams.calculateProtrusionDiffusion = 1; % set to true to calculate the diffusion along the surface of protrusions
            defaultParams.numDiffusionIterations = 600; % 400 number of times the protrusions are diffused 
            defaultParams.calculateDistanceTransformProtrusions = 1; % set to true to calculate the distance transform of the protrusions segmentation                        
            defaultParams.ChannelIndex = 1:numel(owner.channels_); % see class method setPara above
            defaultParams.channels = 'all'; % the channels to mesh, set to 'all' for all the channels or give an array of channel numbers
            defaultParams.InputImageProcessIndex = []; % TODO -- Process Output to use as input to the deconvolution, empty implies raw images

            defaultParams.OutputDirectory = fullfile(ip.Results.outputDir,'Morphology','Analysis','IntensityBlebCompare');        
            defaultParams = prepPerChannelParams(defaultParams, nChan);                      
        
        end
        
    end
end
