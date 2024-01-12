% KDTREE_BUILD construct a kd-tree from a point cloud
%
% SYNTAX
% tree = kdtree_build(p)
%
% INPUT PARAMETERS
%   P: a set of N k-dimensional points stored in a 
%      NxK matrix. (i.e. each row is a point)
%
% OUTPUT PARAMETERS
%   tree: a pointer to the created data structure
%
% DESCRIPTION
% Given a point set p, builds a k-d tree as specified in [1] 
% with a preprocessing time of O(d N logN), N number of points, 
% d the dimensionality of a point
% 
% See also:
% KDTREE_BUILD_DEMO, KDTREE_NEAREST_NEIGHBOR, 
% KDTREE_RANGE_QUERY, KDTREE_K_NEAREST_NEIGHBORS
%
% References:
% [1] M. De Berg, O. Cheong, and M. van Kreveld. 
%     Computational Geometry: Algorithms and 
%     Applications. Springer, 2008.
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

% Copyright (c) 2008 Andrea Tagliasacchi
% All Rights Reserved
% email: ata2@cs.sfu.ca 
% $Revision: 1.0$  Created on: 2008/09/15
