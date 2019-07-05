%[res, theta, nms] = steerableDetector3D(vol, M, sigma, zxRatio) performs curve/surface detection using 3D steerable filters
%
% Inputs: 
%         vol : input volume
%           M : filter type
%               1: curve detector
%               2: surface detector
%               3: volume/edge detector (gradient magnitude)
%       sigma : standard deviation of the Gaussian kernel on which the filters are based
%   {zxRatio} : correction factor for z anisotropy (default: 1).
%               Example: if the z sampling step is 5x larger than xy-sampling, set this value to 5.
%
% Outputs: 
%         res : response to the filter
%       theta : orientation vector component structure:
%               .x1, .x2, .x3 fields
%         nms : non-maximum-suppressed response
%
% Memory usage: ~17x size of 'vol'
%
% For more information, see:
% F. Aguet et al., IEEE Proc. ICIP'05, pp. II 1158-1161, 2005.
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

% Francois Aguet, 08/2012 (last modified 08/28/2012).

function [res, theta, nms] = steerableDetector3D(vol, M, sigma, zxRatio) %#ok<STOUT,INUSD>