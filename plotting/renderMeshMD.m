function [meshHandle, figHandle] = renderMeshMD(processOrMovieData, varargin)
% renderMeshMD - wraps plotMeshMD (via RenderMeshProcess) to create custom renderings via a GUI and export to other formats (e.g., .dae)
% Specifically,  plotMeshMDWrapper will check if a .fig has already been created for the desired rendering. 
% Minimally requires that Mesh3DProcess has successfully run. ()
% also see: RenderMeshProcess.m, plotMeshMD.m, Morphology3DPackage.m
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

%Check input
ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('movieData', @(x) isa(x,'Process') && isa(x.getOwner(),'MovieData') || isa(x,'MovieData'));
ip.addOptional('paramsIn',[], @isstruct);
ip.addParameter('ProcessIndex',[],@isnumeric);
ip.parse(processOrMovieData,varargin{:});
paramsIn = ip.Results.paramsIn;

[MD, process] = getOwnerAndProcess(processOrMovieData,'RenderMeshProcess',true);
p = parseProcessParams(process, paramsIn);

process.setOutFilePaths({p.OutputDirectory});

[meshHandle, figHandle] = plotMeshMD(MD, 'chan', p.ChannelIndex, p);

figure(figHandle);
title(p.surfaceMode); figHandle.Name = ['Custom Rendering: < ' p.surfaceMode ' > created '  datestr(now, 'dd-mmm-yyyy HH:MM')];
