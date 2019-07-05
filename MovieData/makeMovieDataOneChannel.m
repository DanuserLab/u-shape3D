function MD = makeMovieDataOneChannel(imageDirectory, saveDirectory, pixelSizeXY, pixelSizeZ, timeInterval)

try 
    MD = MovieData.load(fullfile(saveDirectory,'movieData.mat')); 
catch
    
    % Constructor needs an array of channels and an output directory (for analysis)
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
    ch0 = Channel(imageDirectory);
    MD = MovieData(ch0, saveDirectory);
    MD.setPath(saveDirectory);
    MD.setFilename('movieData.mat');

    MD.numAperture_ = 1.4;
    MD.pixelSize_ = pixelSizeXY; % in nm after binning
    MD.pixelSizeZ_ = pixelSizeZ; % in nm after binning
    MD.timeInterval_= timeInterval; % in sec
    MD.camBitdepth_ = 16;
    MD.notes_ = 'Created for test purposes';
    
    % Save the movieData
    MD.save;
    MD.sanityCheck;
    MD.save;
    MD.reset();
    
    % Load the movie/display contents (verify we can reload the movie as intended
    clear MD;
    MD = MovieData.load(fullfile(saveDirectory,'movieData.mat'));
end

% check that the movie has loaded correctly
% movieViewer(MD);