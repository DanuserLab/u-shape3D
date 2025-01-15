function [maxResp,d2X,d2Y,d2Z,maxRespScale] = multiscaleSurfaceFilter3D(imageIn,varargin)

% (written by Hunter Elliott) 
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

ip = inputParser;
%ip.addRequired('imageIn',@(x)(ndims(x) == 3));
ip.addParamValue('SigmasXY',[1 2 4 6 12],@(x)(all(x>=1)));
ip.addParamValue('SigmasZ',[1 2 4 6 12],@(x)(all(x>=1)));
ip.addParamValue('WeightZ',2,@(x)(numel(x) == 1 && x > 0));
ip.addParamValue('NormResp',false,@(x)(numel(x) == 1 && islogical(x)));
ip.parse(varargin{:});
p = ip.Results;

% sigmasXY = [1.5 2 4 ];%TTTEEEEMMMPPPP!!!
% sigmasZ = sigmasXY*4/3;

nSig = numel(p.SigmasXY);

maxResp = zeros(size(imageIn));
maxRespScale = zeros(size(imageIn));
d2X = zeros(size(imageIn));
d2Y = zeros(size(imageIn));
d2Z = zeros(size(imageIn));

for j = 1:nSig
            
    [d2Xtmp,d2Ytmp,d2Ztmp] = surfaceFilterGauss3D(imageIn,[p.SigmasXY(j) p.SigmasXY(j) p.SigmasZ(j)]);            
    
    d2Xtmp(d2Xtmp<0) = 0;
    d2Ytmp(d2Ytmp<0) = 0;
    d2Ztmp(d2Ztmp<0) = 0;        
        
    
    if p.NormResp
        %Get magnitude and normalize response based on sigma to give comparable
        %responses at different scales. This isn't even the right way to normalize, but we leave it for now in case we need to reproduce old results. Someday I'll have the time to fix this and put in proper scale-normalization....hahahahahahahahah that's funny        
        sMag = sqrt((d2Xtmp * p.SigmasXY(j)) .^2 + ...
                    (d2Ytmp * p.SigmasXY(j)) .^2 + ...
                    (d2Ztmp * p.SigmasZ(j)) .^2 .* p.WeightZ);
    else
        
        sMag = sqrt(d2Xtmp .^2 + d2Ytmp .^2 + d2Ztmp .^2);
    end
    
    isBetter = sMag > maxResp;    
    maxRespScale(isBetter) = j; 
    maxResp(isBetter) = sMag(isBetter);
    d2X(isBetter) = d2Xtmp(isBetter);
    d2Y(isBetter) = d2Ytmp(isBetter);
    d2Z(isBetter) = d2Ztmp(isBetter);
                
end