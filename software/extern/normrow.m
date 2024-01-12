function [ B ] = normrow( A )
  % NORMROW  Compute l2 row vector norms
  %
  % B = normrow( A )
  %
  % Input:
  %  A  #A by D list of row vectors of dimension D
  % Output:
  %  B  #A list of norms of row vectors in A
  %
  % Copyright 2011, Alec Jacobson (jacobson@inf.ethz.ch), Daniele Panozzo
  %
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

  switch size(A,2)
  case 2
    B = hypot(A(:,1),A(:,2));
  otherwise
    %B = sqrt(sum(A.^2,2));
    M = max(abs(A),[],2);
    B = M.*sqrt(sum((A./M).^2,2));
    B(M==0) = 0;
  end
end

