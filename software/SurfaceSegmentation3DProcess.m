classdef SurfaceSegmentation3DProcess < MeshProcessingProcess
    
% Surface segmentation process - 
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
    
    methods (Access = public)
        function obj = SurfaceSegmentation3DProcess(owner, varargin)
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
                super_args{2} = SurfaceSegmentation3DProcess.getName;
                super_args{3} = @surfaceSegmentationMeshMD;
                if isempty(funParams)
                    funParams = SurfaceSegmentation3DProcess.getDefaultParams(owner, outputDir);
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
            addParameter(ip,'blebMode',@ischar);
            addParameter(ip,'triangleRatio',@(x) (isscaler(x) && x>=0 && x<=1));
            addParameter(ip,'otsuRatio',@(x) (isscaler(x) && x>=0 && x<=1));
            addParameter(ip,'losRatio',@(x) (isscaler(x) && x>=0 && x<=1));
            addParameter(ip,'raysPerCompare',@(x) (isscaler(x) && x>=1 && mod(x,1)==0));
            addParameter(ip,'channels',@(x) ~isempty(x));
            addParameter(ip,'OutputDirectory',@ischar);
            addParameter(ip,'ChannelIndex',@isnumeric);
            addParameter(ip,'PerChannelParams',@iscell);
            addParameter(ip,'InputImageProcessIndex',@(x) isempty(x) || isnumeric(x));            
            ip.parse(params);
            paramsMatched = ip.Results;
            paramsUnmatched = ip.Unmatched;
            
            % check the blebMerge parameter
            blebModes = {'triangleMerge', 'losMerge', 'triangleLosMerge', 'triangleLosMergeThenLocal'};
            assert(max(cellfun(@(x) strcmp(x,paramsMatched.blebMode), blebModes)), '%s is an invalid blebMode parameter', paramsMatched.blebMode);
            
            % check the channels parameter
            channelAll = ischar(paramsMatched.channels) && strcmp(paramsMatched.channels, 'all');
            channelNumeric = isnumeric(paramsMatched.channels) && min(ismember(paramsMatched.channels, 1:length(owner.channels_)));
            assert(channelAll | channelNumeric, 'The channels parameter is invalid.')
                        
            % warn the user about unidentified parameters
            if ~isempty(paramsUnmatched)
                names = fieldnames(paramsUnmatched);
                for s = 1:length(names)
                    warning('MATLAB:unusedParam', ['Invalid surface segmentation parameter: ' names{s}]);
                end
            end
            
            % check that all parameters defined in defaultParams are defined here
            namesDefaultParams = fieldnames(obj.getDefaultParams(owner));
            namesParams = fieldnames(paramsMatched);
            assert(isequal(sort(namesDefaultParams), sort(namesParams)), 'Some parameters for the SurfaceSegmentation process are missing.'); 
        end

        function output = getDrawableOutput(obj, varargin)
            % TODO - make fancy method for selected frame to render.
            % for now default to first frame.
            % for n = 1:numel(obj.owner_.channels_)
            validChans = find(obj.checkChannelOutput);
            n = 0; 
            for iCh = validChans
                n = n + 1;
                output(n).name = ['Segmentation Rendering'];
                output(n).var = 'segmentation';
                output(n).formatData = [];
                output(n).type = 'graph';
                output(n).defaultDisplayMethod = @(x)FigDisplay('plotFunc', @plotMeshMDWrapper,...
                                            'plotFunParams', {... % {obj.owner_,...
                                            'surfaceMode', 'surfaceSegment','iChan', iCh});
            end
        end    
    end
    methods (Static)
        function name = getName()
            name = 'SurfaceSegmentation';
        end

        function h = GUI()
            h= @SurfaceSegmentation3DProcessGUI;
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

            defaultParams.blebMode = {'triangleLosMerge'}; % sets the criteria used to merge the watersheds
            defaultParams.raysPerCompare = 20; % an losMerge mode parameter 
            defaultParams.losRatio = 0.70; %0.7 an losMerge mode parameter 
            defaultParams.triangleRatio = 0.70; %0.7 an losMerge and a triangleMerge mode parameter (try using 0.3 in triangleMerge mode, and 0.7 in triangleLos mode)
            defaultParams.otsuRatio = 0.15; %.15 an losMerge and a triangleMerge mode parameter (try using 0.6 in triangleMerge mode, and 0.2 in triangleLos mode)            
            
            defaultParams.PerChannelParams = fieldnames(defaultParams);
            
            defaultParams.ChannelIndex = 1:numel(owner.channels_); % see class method setPara above
            defaultParams.channels = ''; % the channels to mesh, set to 'all' for all the channels or give an array of channel numbers
            defaultParams.InputImageProcessIndex = []; % TODO -- Process Output to use as input to the deconvolution, empty implies raw images

            defaultParams.OutputDirectory = fullfile(ip.Results.outputDir,'Morphology','Analysis','SurfaceSegment');        
            defaultParams = prepPerChannelParams(defaultParams, nChan);                      
        end
        
    end
end
