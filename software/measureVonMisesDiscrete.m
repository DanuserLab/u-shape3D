function [meanDiscreteVM, concDiscreteVM] = measureVonMisesDiscrete(allFaceVectors, downSample, sampleOffset, measure, discreteLevel)

% measureVonMisesDiscrete - calculate the von Mises-Fisher parameters, discretized, for a measure
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

% discretize the measure
measure = measure - min(measure(:));
measure = discreteLevel*measure./max(measure(:));
measure = ceil(measure);
measure(measure<1) = 1;

% for each measure value, append data to the list of unit vectors
unitVectors = [];
for n = sampleOffset:downSample:length(measure) 
    unitVectors = [unitVectors; repmat([allFaceVectors(n,:)], [measure(n), 1])]; 
end

% find the von Mises-Fisher parameters
[meanDiscreteVM, concDiscreteVM] = estimateVonMisesFisherParameters(unitVectors, 3);