function morphology3D(imagePathOrMovieData, varargin)

% morphology3D - runs processes in the the morphology3D package
% 
% INPUTS:
%
% imagePath        - the full path of the movie including the name. For
%                    multi-tiff movies, give the name of any tif in the movie.
%                  - OR 
%                    is a MovieData object containing the movie information.
%
%
% outputDirectory  - the directory where the MovieData object is stored.
%
% parameters       - (optional third input) Process and control parameters
%                  that override defualt parameters. Store control
%                  parameters in parameters.control, so for example
%                  parameters.control.deconvolution toogles deconvolution
%                  on and off. And store process parameters by name, so
%                  parameters.deconvolution.weiner sets the Weiner
%                  parameter for deconvolution.
%
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


%% Parse the inputs
ip = inputParser;
ip.KeepUnmatched = false;
ip.PartialMatching = false;
addRequired(ip, 'imagePath', @(x) ischar(x) || isa(x,'MovieData'));
if ~isempty(varargin) && ischar(varargin)
    % to accomodate legacy scripts
    addOptional(ip, 'outputDirectory', [], @(x) ischar(x) || isempty(x));
end
addOptional(ip, 'parameters', [], @(x) isstruct(x) || isempty(x) );
ip.parse(imagePathOrMovieData, varargin{:});
p = ip.Results.parameters;
imagePath = ip.Results.imagePath;


%% Add the Morphology3D package if needed
% load default control parameters
pDefault.control = defaultControlParamsMorphology3DPackage();

% combine default control parameters with user provided parameters
if ~isfield(p,'control'), p.control = []; end
p.control = combineStructures(pDefault.control, p.control);

if isa(imagePath, 'MovieData')
    MD = imagePath;
    if p.control.resetMD
        MD.reset;
    end
else
    % make an output directory
    if ~isdir(outputDirectory)
        system(['mkdir -p ' outputDirectory]);
    end

    % turn MovieData warnings off
    warning off MovieObject:saveBackup:Failure;

    % load or create a MovieData object
    disp('Loading the movie');
    MD = loadMovieData(imagePath, outputDirectory, 'reset', p.control.resetMD);

end

% check to see if MD has a Morphology3D package associated with it
iPack = MD.getPackageIndex('Morphology3DPackage');

% if it does not, then make a Morphology3D package 
if isempty(iPack)
    MD.addPackage(Morphology3DPackage(MD));
end


%% Run Processes
% deconvolve the movie
if p.control.deconvolution == 1
    disp('Starting deconvolution')
    if ~isfield(p,'deconvolution'), p.deconvolution = []; end
    startProcess(MD, 'Morphology3DPackage', 'Deconvolution3DProcess', p.deconvolution, p.control.deconvolutionReset)
end

% ComputeMIP on the movie
if p.control.computeMIP == 1
    disp('Starting ComputeMIP')
    if ~isfield(p,'computeMIP'), p.computeMIP = []; end
    startProcess(MD, 'Morphology3DPackage', 'ComputeMIPProcess', [], p.control.computeMIPReset)
end

% make surface meshes of cells and calculate curvature
if p.control.mesh == 1
    disp('Starting meshing')
    if ~isfield(p,'mesh'), p.mesh = []; end
    startProcess(MD, 'Morphology3DPackage', 'Mesh3DProcess', p.mesh, p.control.meshReset)
end

% make Threshold Mask of meshes
if p.control.meshThres == 1
    disp('Starting meshing threshold')
    if ~isfield(p,'mesh'), p.mesh = []; end
    startProcess(MD, 'Morphology3DPackage', 'Check3DCellSegmentationProcess', [], p.control.meshThresReset)
end

% segment the cell surface
if p.control.surfaceSegment == 1
    disp('Starting surface segmentation')
    if ~isfield(p,'surfaceSegment'), p.surfaceSegment = []; end
    startProcess(MD, 'Morphology3DPackage', 'SurfaceSegmentation3DProcess', p.surfaceSegment, p.control.surfaceSegmentReset)
end

% calculate statistcs for machine learning or patch merging
if p.control.patchDescribeForMerge == 1
    disp('Starting patch characterization for merging via machine learning')
    if ~isfield(p,'patchDescribeForMerge'), p.patchDescribeForMerge = []; end
    startProcess(MD, 'Morphology3DPackage', 'PatchDescriptionForMerge3DProcess', p.patchDescribeForMerge, p.control.patchDescribeForMergeReset)
end

% merge patches via machine learning
if p.control.patchMerge == 1
    disp('Starting patch merging via machine learning')
    if ~isfield(p,'patchMerge'), p.patchMerge = []; end
    startProcess(MD, 'Morphology3DPackage', 'PatchMerge3DProcess', p.patchMerge, p.control.patchMergeReset)
end

% calculate statistics for patches
if p.control.patchDescribe == 1
    disp('Starting patch characterization')
    if ~isfield(p,'patchDescribe'), p.patchDescribe = []; end
    startProcess(MD, 'Morphology3DPackage', 'PatchDescription3DProcess', p.patchDescribe, p.control.patchDescribeReset)
end

% detect protrusions
if p.control.motifDetect == 1
    disp('Starting motif detection')
    if ~isfield(p,'motifDetect'), p.motifDetect = []; end
    startProcess(MD, 'Morphology3DPackage', 'MotifDetection3DProcess', p.motifDetect, p.control.motifDetectReset)
end

% measure mesh motion
if p.control.meshMotion == 1
    disp('Starting mesh motion measurements')
    if ~isfield(p,'meshMotion'), p.meshMotion = []; end
    startProcess(MD, 'Morphology3DPackage', 'MeshMotion3DProcess', p.meshMotion, p.control.meshMotionReset)
end

% measure surface intensity
if p.control.intensity == 1
    disp('Starting intensity measurements')
    if ~isfield(p,'intensity'), p.intensity = []; end
    startProcess(MD, 'Morphology3DPackage', 'Intensity3DProcess', p.intensity, p.control.intensityReset)
end

% measure surface intensity - bleb correlations
if p.control.intensityBlebCompare == 1
    disp('Starting intensity characterization')
    if ~isfield(p,'intensityBlebCompare'), p.intensityBlebCompare = []; end
    startProcess(MD, 'Morphology3DPackage', 'IntensityMotifCompare3DProcess', p.intensityBlebCompare, p.control.intensityBlebCompareReset)
end
