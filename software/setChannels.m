function p = setChannels(p, cellSegChannel, collagenChannel)

% setChannels - a helper function to more quickly set channels for Morphology3D
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

p.photobleach.channels = cellSegChannel;
p.deconvolution.channels = cellSegChannel;
p.mesh.channels = cellSegChannel;
p.surfaceSegment.channels = cellSegChannel;
p.patchDescribeForMerge.channels = cellSegChannel;
p.patchMerge.channels = cellSegChannel;
p.patchDescribe.channels = cellSegChannel;
p.blebDetect.channels = cellSegChannel;
p.blebTrack.channels = cellSegChannel;
p.motifDetect.channels = cellSegChannel;
p.meshMotion.channels = cellSegChannel;
p.collagenDetect.channels = collagenChannel;
p.collagenDescribe.channels = collagenChannel;
p.collagenDescribe.cellChannel = cellSegChannel;
p.intensity.channels = cellSegChannel;
p.intensity.otherChannel = collagenChannel;
p.intensityBlebCompare.channels = cellSegChannel;