function MD = loadMovieData(imagePath, outputDirectory, varargin)

% load MovieData - initiates a movieData object if there is not one associated with the imagePath at the outputDirectory
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

% INPUTS:
%
% imagePath - the path and name of a movie, or for multi-tiff movies the
%           path and name of one of those tiffs
%
% outputDirectory - the directory where all output data will be saved
%
% reset - (optional) 1 to reset MovieData, 0 to not reset it


% check inputs
ip = inputParser;
addRequired(ip, 'imagePath', @ischar);
addRequired(ip, 'outputDirectory', @ischar);
addParameter(ip, 'reset', 0, @(x) (x==0 || x==1));
ip.parse(imagePath, outputDirectory, varargin{:});
p = ip.Results;

% look for a MovieData object with the same name as the provided image name or with the name movieData
[~,nameStr,~] = fileparts(p.imagePath);
nameMD = [p.outputDirectory filesep nameStr '.mat'];
infoMD = dir(nameMD);
defaultMD = dir(fullfile(p.outputDirectory,'movieData.mat'));

% if there's not a MovieData object then make one
if isempty(infoMD) && isempty(defaultMD) 
    disp('Making a new MovieData object')
    MD = MovieData(p.imagePath, 'outputDirectory', p.outputDirectory);
else % otherwise load the old movie data
    disp('Loading an existing MovieData object')
    if ~isempty(infoMD)
        load(nameMD);
    else
        load(fullfile(p.outputDirectory,'movieData.mat'))
    end
    
    if p.reset == 1 % reset if wanted
        MD.reset();
        disp('Reseting MovieData')
    else % check the MovieData object
        sanityCheck(MD);
    end
end