function [patchLengthSmall, patchLengthBig] = calculatePatchLength(positions, watersheds, faceIndex, firstLabel, secondLabel, meshLength)

% calculatePatchLength - given two patches on a mesh, finds the maximum length in x y or x of the smallest patch (minimum returned patch length is 8)
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

% calculate the minimum patchLength of the two regions
firstFaces = faceIndex(watersheds == firstLabel);
secondFaces = faceIndex(watersheds == secondLabel);
firstSize = max([max(positions(firstFaces,1))-min(positions(firstFaces,1)), ... 
    max(positions(firstFaces,2))-min(positions(firstFaces,2)), max(positions(firstFaces,3))-min(positions(firstFaces,3))]);
secondSize = max([max(positions(secondFaces,1))-min(positions(secondFaces,1)), ... 
    max(positions(secondFaces,2))-min(positions(secondFaces,2)), max(positions(secondFaces,3))-min(positions(secondFaces,3))]);
patchLengthSmall = min([firstSize, secondSize, 0.2*meshLength]);
patchLengthSmall = max([patchLengthSmall, 8]);
patchLengthBig = max([firstSize, secondSize]);