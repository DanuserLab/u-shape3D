function [label, score] = predictFromBlebClicks(clickedOnBlebs, clickedOnNotBlebs, patchList)

% predictFromBlebClicks generates a label and an SVM like score list from the list of clicked on patches
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

% convert clickedOnBlebs to patchList indices
blebsPatchIndex = nan(1,length(clickedOnBlebs));
for b = 1:length(clickedOnBlebs)
    blebsPatchIndex(b) = find(patchList == clickedOnBlebs(b));
end

% convert clickedOnNotBlebs to patchList indices
notBlebsPatchIndex = nan(1,length(clickedOnNotBlebs));
for b = 1:length(clickedOnNotBlebs)
    notBlebsPatchIndex(b) = find(patchList == clickedOnNotBlebs(b));
end

% generate outputs for the 'certain' clicking mode
if ~isempty(clickedOnBlebs) && ~isempty(clickedOnNotBlebs)
    score = zeros(1,length(patchList));
    score(blebsPatchIndex) = score(blebsPatchIndex) + 1;
    score(notBlebsPatchIndex) = score(notBlebsPatchIndex) - 1;
    label = ceil(score/2);
    
% generate outputs for the 'notBleb' clicking mode   
elseif ~isempty(clickedOnNotBlebs)
    score = ones(1,length(patchList));
    score(notBlebsPatchIndex) = score(notBlebsPatchIndex) - 1;
    label = score;

% generate outputs for the 'bleb' clicking mode   
else 
    score = zeros(1,length(patchList));
    score(blebsPatchIndex) = score(blebsPatchIndex) + 1;
    label = score;
end