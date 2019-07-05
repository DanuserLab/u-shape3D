
classdef PatchMerge3DProcess < MeshProcessingProcess
    methods (Access = public)
        function obj = PatchMerge3DProcess(owner, varargin)
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
                super_args{2} = PatchMerge3DProcess.getName;
                super_args{3} = @patchMergeMeshMD;
                if isempty(funParams)
                    funParams = PatchMerge3DProcess.getDefaultParams(owner, outputDir);
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
            addParameter(ip,'channels',@(x) ~isempty(x));
            addParameter(ip,'OutputDirectory',@ischar);
            addParameter(ip,'svmPath',@(x) (ischar(x)) || isempty(x));
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
                    warning('MATLAB:unusedParam', ['Invalid merge patches parameter: ' names{s}]);
                end
            end

            % check the SVM .mat file for patch merging
            assert(exist(paramsMatched.svmPath,'file') == 2, ['The following is not a valid SVM path ' paramsMatched.svmPath]);

            % check that all parameters defined in defaultParams are defined here
            namesDefaultParams = fieldnames(obj.getDefaultParams(owner));
            namesParams = fieldnames(paramsMatched);
            assert(isequal(sort(namesDefaultParams), sort(namesParams)), 'Some parameters for the PatchMerge process are missing.'); 
        end
        function output = getDrawableOutput(obj, varargin)
            % TODO - make fancy method for selected frame to render.
            % for now default to first frame.
            validChans = find(obj.checkChannelOutput);
            n = 0; 
            for iCh = validChans
                n = n + 1;
                output(n).name = ['Patch Merge Rendering'];
                output(n).var = 'Seg Path Merge';
                output(n).formatData = [];
                output(n).type = 'graph';
                output(n).defaultDisplayMethod = @(x)FigDisplay('plotFunc', @plotMeshMDWrapper,...
                                            'plotFunParams', {... % {obj.owner_,...
                                            'surfaceMode', 'surfaceSegmentPatchMerge','chan', iCh});
            end
        end        
    end
    
    methods (Static)
        function name = getName()
            name = 'PatchMerge';
        end

        function h = GUI()
            h = @patchMerge3DProcessGUI;
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

            defaultParams.svmPath = {[]}; % the location of the saved SVM model
            defaultParams.PerChannelParams = fieldnames(defaultParams);

            defaultParams.ChannelIndex = 1:numel(owner.channels_); % see class method setPara above
            defaultParams.channels = '';
            defaultParams.InputImageProcessIndex = []; % TODO -- Process Output to use as input to the deconvolution, empty implies raw images
            
            % set more default parameters
            defaultParams.OutputDirectory = fullfile(ip.Results.outputDir,'Morphology','Analysis','PatchMerge');        
            defaultParams = prepPerChannelParams(defaultParams, nChan);                    
        end
        
    end
end
