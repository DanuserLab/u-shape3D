function defaultControl = defaultControlParamsMorphology3DPackage()

% defaultControlParamsMorphology3DPackage - set default control parameters for the Morphology3D package
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

% resetting the package
defaultControl.resetMD = 0;

% running the processes
defaultControl.deconvolution = 1;
defaultControl.mesh = 1;
defaultControl.surfaceSegment = 1;
defaultControl.patchDescribeForMerge = 1;
defaultControl.patchMerge = 1;
defaultControl.patchDescribe = 1;
defaultControl.motifDetect = 1;
defaultControl.meshMotion = 1;
defaultControl.intensity = 1;
defaultControl.intensityBlebCompare = 1;

% resetting the processes
defaultControl.deconvolutionReset = 0;
defaultControl.meshReset = 0;
defaultControl.surfaceSegmentReset = 0;
defaultControl.patchDescribeForMergeReset = 1;
defaultControl.patchMergeReset = 1;
defaultControl.patchDescribeReset = 0;
defaultControl.motifDetectReset = 0;
defaultControl.meshMotionReset = 0;
defaultControl.intensityReset = 0;
defaultControl.intensityBlebCompareReset = 0;
