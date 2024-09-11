classdef Morphology3DPackage < Package
    
    % Morphology3DPackage is the package associated with the motif detection paper
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
    
    methods
        function obj = Morphology3DPackage(owner,varargin)
            
            % Check input
            ip =inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieObject'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner,varargin{:});
            outputDir = ip.Results.outputDir;

            super_args{1} = owner;
            super_args{2} = [outputDir  filesep 'Morphology']; % Did not change the save folder's name to uShape3DPackage, b/c 'Morphology' was hard-coded in many save folders in this package. 

            % Call the superclass constructor
            obj = obj@Package(super_args{:});
        end
        
        function [status, processExceptions] = sanityCheck(obj, varargin) % throws Exception Cell Array
            
            % %% TODO - add more to sanitycheck
            % disp('TODO: SanityCheck!');
            missingMetadataMsg = ['Missing %s! The %s is necessary to analyze '...
            '3D Cells. Please edit the movie and fill the %s.'];
            errorMsg = @(x) sprintf(missingMetadataMsg, x, x, x);
            
            assert(obj.owner_.is3D, errorMsg('MovieData is not 3D!'));
            assert(~isempty(obj.owner_.pixelSize_), errorMsg('pixel size not defined!'));
            assert(~isempty(obj.owner_.pixelSizeZ_), errorMsg('pixel Z size defined!'));
            [status, processExceptions] = sanityCheck@Package(obj, varargin{:});

        end
        
        function index = getProcessIndexByName(obj, name)
            index = find(cellfun(@(x) strcmp(x,name), obj.getProcessClassNames()));
        end
             
        function status = hasProcessByName(obj, name)
            status = max(cellfun(@(x) strcmp(class(x),name), obj.processes_));
        end
    end
    
    methods (Static)
        
        function classes = getProcessClassNames(index)
            classes = {
                'Deconvolution3DProcess',...
                'ComputeMIPProcess',...
                'Mesh3DProcess',...
                'Check3DCellSegmentationProcess',...
                'SurfaceSegmentation3DProcess',...
                'PatchDescriptionForMerge3DProcess',...
                'PatchMerge3DProcess',...
                'PatchDescription3DProcess',...
                'MotifDetection3DProcess', ...
                'MeshMotion3DProcess', ...
                'Intensity3DProcess', ...
                'IntensityMotifCompare3DProcess', ...
                'RenderMeshProcess'};         
            if nargin == 0, index = 1 : numel(classes); end
            classes = classes(index);
        end
        
        function m = getDependencyMatrix(i,j)
            
            %    1  2  3  4  5  6  7  8  9  10 11 12 13
            m = [0  0  0  0  0  0  0  0  0  0  0  0  0 ; % 1 Deconvolution3DProcess
                 2  0  0  0  0  0  0  0  0  0  0  0  0 ; % 2 ComputeMIPProcess   
                 2  0  0  0  0  0  0  0  0  0  0  0  0 ; % 3 Mesh3DProcess
                 2  0  1  0  0  0  0  0  0  0  0  0  0 ; % 4 Check3DCellSegmentationProcess
                 2  0  1  2  0  0  0  0  0  0  0  0  0 ; % 5 SurfaceSegmentation3DProcess
                 2  0  1  2  1  0  0  0  0  0  0  0  0 ; % 6 PatchDescriptionForMerge3DProcess
                 2  0  1  2  1  1  0  0  0  0  0  0  0 ; % 7 PatchMerge3DProcess
                 2  0  1  2  1  2  2  0  0  0  0  0  0 ; % 8 PatchDescription3DProcess
                 2  0  1  2  1  2  2  1  0  0  0  0  0 ; % 9 MotifDetection3DProcess
                 2  0  1  2  0  0  0  0  0  0  0  0  0 ; % 10 MeshMotion3DProcess
                 2  0  1  2  0  0  0  0  0  0  0  0  0 ; % 11 Intensity3DProcess
                 2  0  1  2  1  2  2  1  1  1  1  0  0 ; % 12 IntensityMotifCompare3DProcess
                 2  0  0  0  0  0  0  0  0  0  0  0  0 ]; % 13 RenderMeshProcess
             
            if nargin<2, j=1:size(m,2); end
            if nargin<1, i=1:size(m,1); end
            m=m(i,j);
        end
        
        function name = getName()
            name = 'u-shape3D'; % renamed from Morphology3D on movieSelectorGUI on 2023-9-12
        end
       
        function varargout = GUI(varargin)
            % Start the package GUI
            varargout{1} = morphology3DPackageGUI(varargin{:});
        end
                 
        function procConstr = getDefaultProcessConstructors(index)
            procConstr = {
                @(x,y)Deconvolution3DProcess(x,y,Deconvolution3DProcess.getDefaultParams(x,y)),...
                @(x,y)ComputeMIPProcess(x,y,ComputeMIPProcess.getDefaultParams(x,y)),...
                @(x,y)Mesh3DProcess(x,y,Mesh3DProcess.getDefaultParams(x,y)), ...
                @(x,y)Check3DCellSegmentationProcess(x,y,Check3DCellSegmentationProcess.getDefaultParams(x,y)), ...
                @(x,y)SurfaceSegmentation3DProcess(x,y,SurfaceSegmentation3DProcess.getDefaultParams(x,y)), ...
                @(x,y)PatchDescriptionForMerge3DProcess(x,y,PatchDescriptionForMerge3DProcess.getDefaultParams(x,y)), ...
                @(x,y)PatchMerge3DProcess(x,y,PatchMerge3DProcess.getDefaultParams(x,y)),...
                @(x,y)PatchDescription3DProcess(x,y,PatchDescription3DProcess.getDefaultParams(x,y)),...
                @(x,y)MotifDetection3DProcess(x,y,MotifDetection3DProcess.getDefaultParams(x,y)),...
                @(x,y)MeshMotion3DProcess(x,y,MeshMotion3DProcess.getDefaultParams(x,y)),...
                @(x,y)Intensity3DProcess(x,y,Intensity3DProcess.getDefaultParams(x,y)),...
                @(x,y)IntensityMotifCompare3DProcess(x,y,IntensityMotifCompare3DProcess.getDefaultParams(x,y)),...
                @(x,y)RenderMeshProcess(x,y,RenderMeshProcess.getDefaultParams(x,y))};
              
            if nargin == 0, index = 1 : numel(procConstr); end
            procConstr = procConstr(index);
        end
    end  
end
