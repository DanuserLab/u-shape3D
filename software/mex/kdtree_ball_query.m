% KDTREE_BALL_QUERY query a kd-tree with a ball
%
% SYNTAX
% idxs = kdtree_ball_query(tree, qpoint, qradii)
% [idxs, distances] = kdtree_ball_query(tree, qpoint, qradii);
% 
% INPUT PARAMETERS
%   tree:   a pointer to a valid kdtree structure
%   qpoint: a k-dimensional point speficying the center of the ball
%   qradii: a scalar representing the radius of the ball
% 
% OUTPUT PARAMETERS
%   idxs: a column vector of scalars that index the point database.
%         All the index of points that satisfy the ball query are
%         reported in idxs. No particular ordering is provided
% 
% 	distances: the dinstances from the query result points 
%              to the query point (optional) 
%
% DESCRIPTION
% The ball query is implemented as simple generalization
% of the range query. A range query which inscribes the sphere
% in each dimension is made to the kd-tree, then, the points
% are checked against the distance requirement from the query
% point. A more efficient implementation can be sought.
%
% See also:
% KDTREE_BALL_QUERY_DEMO, KDTREE_BUILD, KDTREE_RANGE_QUERY
%
% References:
% [1] M.De Berg, O.Cheong, and M.van Kreveld. 
%     Computational Geometry: Algorithms and 
%     Applications. Springer, 2008.
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

% Copyright (c) 2008 Andrea Tagliasacchi
% All Rights Reserved
% email: ata2@cs.sfu.ca 
% $Revision: 1.0$  Created on: 2008/09/15
