function [d2X,d2Y,d2Z] = surfaceFilterGauss3D(input, sigma, borderCondition)
%SURFACEFILTERGAUSS3D :	surface filters a data volume with a 3-D Gaussian second derivative kernel
%
%    [d2X,d2Y,d2Z] = surfaceFilterGauss3D(image, sigma, borderCondition);
%
%       Filters the input matrix using partial second derivatives of a gaussian,
%       giving a filtered "surface" image. Note that the second derivatives
%       of the gaussian are inverted so that the response is positive at
%       bright surfaces and negative at troughs.
%
%    INPUT: image           : 3-D input array
%           sigma           : standard deviation of the Gaussian to use
%                             derivatives of for filtering. If scalar, same
%                             sigma is used for all dimensions, if 3
%                             element vector then specifies different
%                             sigmas for each dimension.
%           borderCondition : input for 'padarrayXT'. Default: 'symmetric'
%                             Options: 'symmetric', 'replicate', 'circular', 'antisymmetric', or a constant value
%
%    OUTPUT: [d2X,d2Y,d2Z] : Matrices filtered with partial derivatives of the
%                         gaussian in the X, Y and Z directions
%                         respectively, corresponding to matrix dimensions
%                         2, 1 and 3 respectively.
%
% Hunter Elliott, added 01/21/2010
% Modelled after filterGauss3D.m - thanks Francois!
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

if nargin < 3 || isempty(borderCondition)
    borderCondition = 'symmetric';
end

if numel(sigma) == 1
    sigma = repmat(sigma,1,3);
end

w = ceil(5*sigma(1)); % cutoff radius of the gaussian kernel
x = -w:w;
g = exp(-x.^2/(2*sigma(1)^2));
d2g = -(x.^2/sigma(1)^2 - 1) / sigma(1)^2 .* exp(-x.^2/(2*sigma(1)^2));
gSum = sum(g);
g = g/gSum;
d2g = d2g/gSum;

d2X = convn(padarrayXT(input, [w w w], borderCondition), d2g, 'valid');
d2X = convn(d2X, g', 'valid');
d2X = convn(d2X,reshape(g,[1 1 2*w+1]),'valid');

w = ceil(5*sigma(2)); % cutoff radius of the gaussian kernel
x = -w:w;
g = exp(-x.^2/(2*sigma(2)^2));
d2g = -(x.^2/sigma(2)^2 - 1) / sigma(2)^2 .* exp(-x.^2/(2*sigma(2)^2));
gSum = sum(g);
g = g/gSum;
d2g = d2g/gSum;

d2Y = convn(padarrayXT(input, [w w w], borderCondition), g, 'valid');
d2Y = convn(d2Y, d2g', 'valid');
d2Y = convn(d2Y,reshape(g,[1 1 2*w+1]),'valid');

w = ceil(5*sigma(3)); % cutoff radius of the gaussian kernel
x = -w:w;
g = exp(-x.^2/(2*sigma(3)^2));
d2g = -(x.^2/sigma(3)^2 - 1) / sigma(3)^2 .* exp(-x.^2/(2*sigma(3)^2));
gSum = sum(g);
g = g/gSum;
d2g = d2g/gSum;

d2Z = convn(padarrayXT(input, [w w w], borderCondition), g, 'valid');
d2Z = convn(d2Z, g', 'valid');
d2Z = convn(d2Z,reshape(d2g,[1 1 2*w+1]),'valid');
