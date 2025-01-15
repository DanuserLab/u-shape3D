function [meshHandle, figHandle] = plotMeshMDWrapper(dataIn, varargin)
% plotMeshMDWrapper - wraps plotMeshMD to add convenience functions associated with the GUI
% Specifically,  plotMeshMDWrapper will check if a .fig has already been created for the desired rendering. 
% Minimally requires that Mesh3DProcess has successfully run.
% also see: plotMeshMD.m
% Andrew R. Jamieson, July 2018
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

%Check input
ip = inputParser;
ip.KeepUnmatched = true;
ip.CaseSensitive = false;
ip.addRequired('dataIn', @(x) isstruct(x) && isa(x.obj,'Process') && isa(x.obj.getOwner(),'MovieData'));
addParameter(ip, 'surfaceMode', 'blank', @ischar);
addParameter(ip, 'chan', 1, @(x) (isscalar(x) && x>=0));
addParameter(ip, 'iFrame', [], @(x) (isscalar(x) && x>=0));
addParameter(ip, 'figHandleIn',[],@isgraphics);
ip.parse(dataIn,varargin{:});

p = ip.Results;
meshProcess = dataIn.obj;
MD = meshProcess.owner_;

if (isempty(p.iFrame)) && isfield(dataIn,'iFrame') && dataIn.iFrame ~= 1
    p.iFrame = dataIn.iFrame;
else
    p.iFrame = 1;
end

switch p.surfaceMode
	case 'curvature'
		figFile = [meshProcess.outFilePaths_{3,1} filesep 'meshCurvature_' num2str(p.chan) '_' num2str(p.iFrame) '.fig'];
	case 'surfaceSegment'
        figFile = [meshProcess.outFilePaths_{3,1} filesep 'surfaceSegment_' num2str(p.chan) '_' num2str(p.iFrame) '.fig'];
    case 'surfaceSegmentPatchMerge'
        figFile = [meshProcess.outFilePaths_{3,1} filesep 'surfaceSegmentPatchMerge_' num2str(p.chan) '_' num2str(p.iFrame) '.fig'];
	case 'protrusions'
        figFile = [meshProcess.outFilePaths_{3,1} filesep 'protrusions_' num2str(p.chan) '_' num2str(p.iFrame) '.fig'];
	case 'motion'
       % Take care to avoid missing data for motion analysis.
        motionProc = MD.findProcessTag('MeshMotion3DProcess',false, false,'tag',false,'last');
        motionMode = motionProc.funParams_.motionMode;
        if strcmp(motionMode,'backwards') 
            if p.iFrame == 1
                warning('Setting frame number to 2 , no data exists for 1st frame in (backward) motion analysis');
                p.iFrame = 2;
                ff = ancestor(p.figHandleIn,'Figure');
                ff.Name = [ff.Name(1:end-1) num2str(p.iFrame)];
            end
        elseif strcmp(motionMode,'forwards') 
            if p.iFrame == MD.nFrames_
                warning('Setting frame number to N-1 , no data exists for last frame in (forward) motion analysis');
                p.iFrame = MD.nFrames_ - 1;
                ff = ancestor(p.figHandleIn,'Figure');
                ff.Name = [ff.Name(1:end-1) num2str(p.iFrame)];
            end
        end
        figFile = [meshProcess.outFilePaths_{3,1} filesep 'motion_' num2str(p.chan) '_' num2str(p.iFrame) '.fig'];
	case 'intensity'
		figFile = [meshProcess.outFilePaths_{3,1} filesep 'intensity_' num2str(p.chan) '_' num2str(p.iFrame) '.fig'];
	otherwise
		figFile = [meshProcess.outFilePaths_{3,1} filesep p.surfaceMode num2str(p.chan) '_' num2str(p.iFrame) '.fig'];
end 

if exist(figFile, 'file') == 2
	disp(['Loading figure ' figFile]);
    g = openfig(figFile, 'invisible');
    copyobj(get(g, 'Children'), p.figHandleIn.Parent);
    axis(p.figHandleIn, 'off');
    fig_load = ancestor(p.figHandleIn,'figure','toplevel');
    fig_load.Color = [0, 0, 0];
    close(g);
    meshHandle = [];
else
	[meshHandle, figHandle] = plotMeshMD(MD, 'surfaceMode', p.surfaceMode, ...
                                     'chan', p.chan, 'frame', p.iFrame,...
                                     'figHandleIn', p.figHandleIn, varargin{:});
    disp(['Saving figure ' figFile]);
%     figHandle = ancestor(meshHandle,'figure','toplevel');
    savefig(figHandle, figFile);
end