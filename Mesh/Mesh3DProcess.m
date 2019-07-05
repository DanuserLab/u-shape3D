classdef Mesh3DProcess < ImageAnalysisProcess
    
    methods (Access = public)
        function obj = Mesh3DProcess(owner,varargin)
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
                super_args{2} = Mesh3DProcess.getName;
                super_args{3} = @meshMovieMD;
                if  isempty(funParams)
                    funParams = Mesh3DProcess.getDefaultParams(owner, outputDir);
                end
                super_args{4} = funParams;
            end
            obj = obj@ImageAnalysisProcess(super_args{:});
        end 
        function output = loadChannelOutput(obj, iChan, varargin);
               output = [];         
        end
        function checkParameters(obj, owner, params) 
            % check that the parameters inputted are valid
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.StructExpand = true;
            addParameter(ip,'useUndeconvolved',@(x) (x==0 || x==1));
            addParameter(ip,'meshMode',@ischar);
            addParameter(ip,'scaleOtsu',@(x) (isscaler(x) && x>=0));
            addParameter(ip,'imageGamma',@(x) (isscaler(x) && x>0));
            addParameter(ip,'smoothImageSize',@(x) (isscaler(x) && x>=0));
            addParameter(ip,'smoothMeshMode',@ischar);
            addParameter(ip,'smoothMeshIterations',@(x) (isscaler(x) && x>=0 && mod(x,1)==0));
            addParameter(ip,'curvatureMedianFilterRadius',@(x) (isscaler(x) && x>=0 && isinteger(x)));
            addParameter(ip,'curvatureSmoothOnMeshIterations',@(x) (isscaler(x) && x>=0 && isinteger(x)));
            addParameter(ip,'channels',@(x) ~isempty(x));
            addParameter(ip,'multicellGaussSizePreThresh',@(x) (isscaler(x) && x>=0 && isinteger(x)));
            addParameter(ip,'multicellMinVolume',@(x) (isscaler(x) && x>=0));
            addParameter(ip,'multicellDilateRadius',@(x) (isscaler(x) && x>=0 && isinteger(x)));
            addParameter(ip,'multicellCellIndex',@(x) (isscaler(x) && x>=0 && isinteger(x)));
            addParameter(ip,'filterScales', @(x) (isvector(x) && sum(mod(x,1))==0 && sum(x<0)==0));
            addParameter(ip,'steerableType',@(x) (x==1 | x==2));
            addParameter(ip,'filterNumStdSurface',@(x) (isscaler(x) && x>0));
            addParameter(ip,'insideGamma',@(x) (isscaler(x) && x>0));
            addParameter(ip,'insideBlur',@(x) (isscaler(x) && x>0));
            addParameter(ip,'insideDilateRadius',@(x) (isscaler(x) && x>=0 && isinteger(x)));
            addParameter(ip,'insideErodeRadius',@(x) (isscaler(x) && x>=0 && isinteger(x)));
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
            
            % check the meshMode parameter
            meshModes = {'otsu', 'otsuMulticell', 'otsuSteerable', 'stdSteerable', 'twoLevelSurface', 'threeLevelSurface'};
            assert(max(cellfun(@(x) strcmp(x,paramsMatched.meshMode), meshModes)), '%s is an invalid meshMode parameter', paramsMatched.meshMode);

            % check the smoothMeshMode parameter
            smoothMeshModes = {'curvature', 'none'};
            assert(max(cellfun(@(x) strcmp(x,paramsMatched.smoothMeshMode), smoothMeshModes)), '%s is an invalid smoothMeshMode parameter', paramsMatched.smoothMeshMode);
            
            % warn the user about unidentified parameters
            if ~isempty(paramsUnmatched)
                names = fieldnames(paramsUnmatched);
                for s = 1:length(names)
                    warning('MATLAB:unusedParam', ['Invalid mesh parameter: ' names{s}]);
                end
            end
            
            % check that all parameters defined in defaultParams are defined here
            namesDefaultParams = fieldnames(obj.getDefaultParams(owner));
            namesParams = fieldnames(paramsMatched);
            assert(isequal(sort(namesDefaultParams), sort(namesParams)), 'Some parameters for the Mesh process are missing.'); 
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
            obj.setParameters@Process(params, varargin{:})
        end
        function setPara(obj, params, varargin)
            % overloaded method to conform Meghan's channel parameter to standard naming convention for GUI and API
            if isfield(params, 'channels')
                if ischar(params.channels) && strcmp('all', params.channels)
                    params.ChannelIndex = 1:numel(obj.owner_.channels_);
                elseif isnumeric(params.channels)
                    params.ChannelIndex = params.channels;
                end
            end
            obj.setPara@Process(params, varargin{:})
        end
        function output = getDrawableOutput(obj, varargin)
            % TODO - make fancy method for selected frame to render.
            % for now default to first frame.
            % check that channel data exists
            validChans = find(obj.checkChannelOutput);
            n = 0; 
            for iCh = validChans
                n = n + 1;
                output(n).name = ['Curvature Rendering'];
                output(n).var = 'curvature';
                output(n).formatData = [];
                output(n).type = 'graph';
                output(n).defaultDisplayMethod = @(x)FigDisplay('plotFunc', @plotMeshMDWrapper,...
                                            'plotFunParams', {... % {obj.owner_,...
                                            'surfaceMode', 'curvature','iChan', iCh});
            end
        end    
        function status = checkChannelOutput(obj,varargin)
            % Input check -- TODO - fix up
            ip =inputParser;
            ip.addOptional('iChan',1:numel(obj.owner_.channels_),...
                @(x) all(obj.checkChanNum(x)));
            ip.parse(varargin{:});
            iChan=ip.Results.iChan;
            
            %Makes sure there's at least one output file per channel
            status =  arrayfun(@(x) (exist(obj.outFilePaths_{1,x},'dir') && ...
                numel(dir([obj.outFilePaths_{1,x} filesep '*.mat']))>=1),iChan);
        end
        function h = draw(obj,iChan,varargin)
            % Input check
            if ~ismember('getDrawableOutput',methods(obj)), h=[]; return; end
            outputList = obj.getDrawableOutput();
            ip = inputParser;
            ip.addRequired('obj',@(x) isa(x,'Process'));
            ip.addRequired('iChan',@isnumeric);
            ip.addOptional('iFrame',[],@isnumeric);
            ip.addParameter('output',outputList(1).var,@(x) any(cellfun(@(y) isequal(x,y),{outputList.var})));
            ip.addParameter('useCache', false, @islogical);
            ip.addParameter('movieOverlay', false, @islogical);
            ip.KeepUnmatched = true;
            ip.parse(obj,iChan,varargin{:});
            p = ip.Results;
%             data = obj.owner_;
            data = p;
            iOutput = find(cellfun(@(y) isequal(ip.Results.output,y),{outputList.var}));
            
            % Initialize display method
            % Note use obj.resetDisplayMethod(); to reset if problems
            if isempty(obj.getDisplayMethod(iOutput,iChan))
                obj.setDisplayMethod(iOutput, iChan,...
                    outputList(iOutput).defaultDisplayMethod(iChan));
            end
            
            % Create graphic tag and delegate drawing to the display class
            tag = ['process' num2str(obj.getIndex()) '_channel' num2str(iChan) '_output' num2str(iOutput)];
            if ip.Results.movieOverlay % if not channel specific (to match what movieViewer expects)
                tag = ['process' num2str(obj.getIndex()) '_output' num2str(iOutput)];
            end
            h = obj.getDisplayMethod(iOutput, iChan).draw(data,tag,ip.Unmatched);
        end
    end
    
    methods (Static)
        function name = getName()
            name = 'Mesh';
        end
        
        function h = GUI()
            h = @mesh3DProcessGUI;
            % h = @cliGUI()
        end
        
        function defaultParams = getDefaultParams(owner,varargin)
            % check inputs
            ip = inputParser;
            ip.addRequired('owner', @(x) isa(x, 'MovieObject'));
            ip.addOptional('outputDir', owner.outputDirectory_, @ischar);
            ip.parse(owner)

            nChan = numel(owner.channels_);
            defaultParams = struct();                        
        
            defaultParams.useUndeconvolved = 0; 
            defaultParams.meshMode = {'otsu'}; % modes: 'otsu', 'otsuMulticell', 'otsuSteerable', 'twoLevelSurface', 'threeLevelSurface'
            defaultParams.scaleOtsu = 1; % an Otsu threshold multiplier
            defaultParams.imageGamma = 1; % gamma adjust prior to thresholding
            defaultParams.smoothImageSize = 0; % the std of the Gaussian kernal used to smooth the image
            defaultParams.smoothMeshMode = {'curvature'}; % modes: 'curvature', 'none'
            defaultParams.smoothMeshIterations = 6; 
            defaultParams.curvatureMedianFilterRadius = 2; % the radius (in pixels) of a real-space median filter that smoothes curvature
            defaultParams.curvatureSmoothOnMeshIterations = 20; % 12 the number of iterations that curvature is allowed to diffuse on the mesh geometry

            % otsuMulticell parameters
            defaultParams.multicellGaussSizePreThresh = 1; %
            defaultParams.multicellMinVolume = 1000; % in cubic micrometers  
            defaultParams.multicellDilateRadius = 12; % in pixels
            defaultParams.multicellCellIndex = 1; % analyze the brightest cell

            % steerable and surface filter parameters
            defaultParams.filterScales = {[1.5 2 4]}; % the scales in pixels over which the steerable or surface filter is run
            defaultParams.filterNumStdSurface = 2; %  the number of standard deviations above the mean that the surface filter is thresholded at
            defaultParams.steerableType = 1; % the type of steerable filter: 1 for lines and 2 for surfaces
            defaultParams.insideGamma = 0.6; % a gamma correction aplied to the image prior to steerable or surface filtering
            defaultParams.insideBlur = 2; % the standard deviation of a Gaussian blur of the image for the "inside" mask of the three level segmentation
            defaultParams.insideDilateRadius = 5; % morphological dilation size for the "inside" mask of the three level segmentation
            defaultParams.insideErodeRadius = 6.5; % morphological erosion size for the "inside" mask of the three level segmentation
            
            defaultParams.PerChannelParams = fieldnames(defaultParams);
                
            defaultParams.ChannelIndex = 1:numel(owner.channels_); % see class method setPara above
            defaultParams.channels = ''; % the channels to mesh, set to 'all' for all the channels or give an array of channel numbers
            defaultParams.InputImageProcessIndex = []; % TODO -- Process Output to use as input to the deconvolution, empty implies raw images
            % set more default parameters
            defaultParams.OutputDirectory = fullfile(ip.Results.outputDir,'Morphology', 'Analysis','Mesh');        
            defaultParams = prepPerChannelParams(defaultParams, nChan);                    
        end
        
    end
end
