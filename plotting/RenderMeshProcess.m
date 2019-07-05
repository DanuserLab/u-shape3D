classdef RenderMeshProcess < MeshProcessingProcess
    
    methods (Access = public)
        function obj = RenderMeshProcess(owner, varargin)
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
                super_args{2} = RenderMeshProcess.getName;
                super_args{3} = @renderMeshMD;
                if isempty(funParams)
                    funParams = RenderMeshProcess.getDefaultParams(owner, outputDir);
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
            addParameter(ip,'OutputDirectory',@ischar);
            addParameter(ip,'ChannelIndex',@isnumeric);
            addParameter(ip, 'surfaceMode', 'blank', @ischar);
            addParameter(ip, 'frame', 1, @(x) (isscalar(x) && x>0));
            addParameter(ip, 'meshMode', 'surfaceImage', @ischar);
            addParameter(ip, 'surfaceChannel', 'self', @(x) (ischar(x)  || (isscalar(x) && isnumeric(x) && x>0)));
            addParameter(ip, 'setView', [0,90], @(x) (isnumeric(x) && length(x)==2));
            addParameter(ip, 'makeRotation', 0, @(x) (x==0 || x==1));
            addParameter(ip, 'rotSavePath', '', @(x) ischar(x) || isempty(x));
            addParameter(ip, 'makeMovie', 0, @(x) (x==0 || x==1));
            addParameter(ip, 'movieSavePath', '', @ischar);
            addParameter(ip, 'daeSaveName', '', @ischar);
            addParameter(ip, 'meshAlpha', 1,  @(x) (isscalar(x) && x>0 && x<=1));
            addParameter(ip, 'makeColladaDae', 0, @(x) (x==0 || x==1));
            addParameter(ip, 'daeSavePathMain', '',@ischar);
            addParameter(ip, 'surfaceSegmentInterIter', 1, @(x) (isscalar(x) && x>0));
            ip.parse(params);
            paramsMatched = ip.Results;
            paramsUnmatched = ip.Unmatched;
            
            % check the channels parameter
            % warn the user about unidentified parameters
            
            % check that all parameters defined in defaultParams are defined here
            namesDefaultParams = fieldnames(obj.getDefaultParams(owner));
            namesParams = fieldnames(paramsMatched);
            assert(isequal(sort(namesDefaultParams), sort(namesParams)), 'Some parameters for the PatchDescriptionForMerge process are missing.'); 
        end

        function [validMoiveNames, validMoviePaths] = checkOutputsAVI(obj)
            % addChannel check too
            % Check if .avi files exist
            paths = dir(obj.funParams_.movieAVISavePath);
            paths = paths(cellfun(@(x) x>0, {paths.bytes}));
            validMoviePaths = paths(arrayfun(@(x) contains(x, '.avi'), {paths.name},'unif',1));
            validMoiveNames = {validMoviePaths.name};
        end

        function output = getDrawableOutput(obj, varargin)
            % TODO - make fancy method for selected frame to render.

            try 
                [aviMoives, aviMoviePaths] = obj.checkOutputsAVI;
            catch
                aviMovies = {};
            end
            output.type = 'null';
            n = 0;
            
            for i = 1:numel(aviMoives)
                n = n + 1;
                aviPath = fullfile(aviMoviePaths(n).folder, aviMoviePaths(n).name);
                output(n).name = aviMoives{n};
                output(n).var = ['renderavi' num2str(n)];
                output(n).formatData = [];
                output(n).type = 'graph';
                output(n).defaultDisplayMethod = @(x)FigDisplay('plotFunc', @RenderMeshProcess.showMovieGUI,...
                                            'plotFunParams', {... % {obj.owner_,...
                                            'AVImoviePath', aviPath});
            end
        end  
    end
    
    methods (Static)
        function name = getName()
            name = 'RenderMeshTool';
        end

        function h = GUI()
            h = @RenderMeshProcessGUI;
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

            defaultParams.surfaceMode = 'blank';
            defaultParams.frame = 1;
            defaultParams.meshMode =  'surfaceImage';
            defaultParams.surfaceChannel = 'self';
            defaultParams.setView = [0, 90];
            defaultParams.makeRotation = 0;
            defaultParams.rotSavePath = fullfile(ip.Results.outputDir,'Morphology','Outputs','Rotations');
            defaultParams.makeMovie = 0;
            defaultParams.movieSavePath = fullfile(ip.Results.outputDir,'Morphology','Outputs','Movies');
            defaultParams.daeSaveName = '';
            defaultParams.daeSavePathMain = fullfile(ip.Results.outputDir,'Morphology','Outputs','Collada');
            defaultParams.makeMovieAVI = 1;
            defaultParams.movieAVISavePath = fullfile(ip.Results.outputDir,'Morphology','Outputs','MoviesAVI');
            defaultParams.meshAlpha = 1;
            defaultParams.makeColladaDae = 0;
            defaultParams.surfaceSegmentInterIter = 1;
            defaultParams.ChannelIndex = 1;            

            % set more default parameters
            defaultParams.OutputDirectory = fullfile(ip.Results.outputDir,'Morphology','Outputs');%,'RenderMesh');        
        end
        
        function figTop = showMovieGUI(dataIn, varargin)
            % also see: plotMeshMDWrapper.m
            % Andrew R. Jamieson, Oct 2018

            %Check input
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.CaseSensitive = false;
            ip.addRequired('dataIn', @(x) isstruct(x) && isa(x.obj,'Process') && isa(x.obj.getOwner(),'MovieData'));
            addParameter(ip, 'AVImoviePath', '',@(x) ischar(x) && exist(x, 'file') == 2);
            addParameter(ip, 'chan', 1, @(x) (isscalar(x) && x>=0));
            addParameter(ip, 'iFrame', [], @(x) (isscalar(x) && x>=0));
            addParameter(ip, 'figHandleIn',[],@isgraphics);
            addParameter(ip, 'useBlackBkg',1, @(x) (x==0 || x==1));
            ip.parse(dataIn,varargin{:});

            p = ip.Results;
            RenderProcess = dataIn.obj;
            AVImoviePath = p.AVImoviePath;
            rotationAVI = strfind(AVImoviePath, 'Rotation')
            figHandle = p.figHandleIn;
            MD = RenderProcess.owner_;
            
            figTop = ancestor(figHandle, 'figure','toplevel');
            
            if p.useBlackBkg
                figHandle.Color = [0, 0, 0];
                figTop.Color = [0, 0, 0];
            end
            
            if isempty(rotationAVI) && MD.nFrames_ > 1
                SliderStepValue  = [1/(MD.nFrames_-1) 0.5];
                minFrame = 1;
                maxFrame = MD.nFrames_;
            elseif ~isempty(rotationAVI) && rotationAVI > 1
                minFrame = 1;
                maxFrame = 360;
                SliderStepValue = [1/359 0.5];
            else
                SliderStepValue  = [1 0.5];
                minFrame = 1;
                maxFrame = 1;
            end
            
            handles.frameSlider = ... 
                uicontrol(figTop, 'Style', 'slider', 'Units', 'pixels', ...
                        'Value', 1, 'Min', minFrame, 'Max',maxFrame, 'SliderStep', SliderStepValue, ...
                        'Position',[85 5 390 14],'Callback', @frameSliderRelease_Callback);
            figHandle.XAxis.Visible = 'off';
            figHandle.YAxis.Visible = 'off';
            
            handles.animateButton = uicontrol('Style','pushbutton', ...
                        'Tag','AnitmateAVIButton',...
                        'Position',[10 20 85 55],...
                        'FontSize', 12,...
                        'String', 'Animate', ...
                        'Callback', @AnimateButtonPushed_Callback);            
%                     'ButtonDownFcn', @AnimateButtonPushed_Callback);            
            
            vR = VideoReader(AVImoviePath);
            ni = 0;
            movieFrame = struct('cdata', zeros(vR.Height,vR.Width,3,...
                                'uint8'),...
                                'colormap',[]);
            
            while hasFrame(vR)
                ni = ni + 1;
                movieFrame(ni).cdata = readFrame(vR);
            end
            
%             size(movieFrame)
            imagesc(movieFrame(handles.frameSlider.Value).cdata,'Parent', figHandle, 'HitTest', 'off');    
            
            function frameSliderRelease_Callback(source, ~)
                val = source.Value;
                handles.iFrame = round(val);
                imagesc(movieFrame(handles.iFrame).cdata,'Parent',...
                        figHandle);    
                set(figHandle, 'XTick', []);
                set(figHandle, 'YTick', []);
            end
               
            
            function AnimateButtonPushed_Callback(source, ~)
                for i = 1:numel(movieFrame)
                    imagesc(movieFrame(i).cdata, 'Parent', figHandle);
                    pause(1/vR.FrameRate);
                    handles.frameSlider.Value = i;
                end
 
            end
        end
    end
end
