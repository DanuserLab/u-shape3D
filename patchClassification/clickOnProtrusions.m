function clickOnProtrusions(p)

% clickOnProtrusions - select protrusions by clicking on them with a GUI
%
% INPUTS
%   p.nameOfClicker - the ID or name of the person clicking
%   
%   p.mode - specifes which experiments to validate
%     'restart'  - validates all the experiments starting at the begining
%     'continue' - begins validatation at the first non-completed experiment
%     a vector   - to validate specific experiments specify a list of
%                  experiment indices, for example [1 3 4] would validate 
%                  the first, third, and fourth experiments
%
%   p.mainDirectory - the directory where Morphology3D information is saved
% 
%   p.cellsList - the list of directories of cells to click on
% 
%   p.framesPerCell - number of frames to select 
%
%   p.surfaceMode
%     'blank' - do not color code the surface (default)
%     'curvature' - color the surface by curvature
%     'surfaceSegment' - color the surface by surface segmentation
%     'surfaceSegmentPatchMerge' - color the surface by post-patch-merge surface segmentation
%
%   p.clickMode
%     'clickOnProtrusions' - ask the user to click on protrusions (only works with 2 classes)
%     'clickOnNotProtrusions' - ask the user to click on protrusions (only works with 2 classes)
%     'clickOnCertain' - ask the user to click on features that are
%           certainly blebs, and then ask the user to click on features
%           that are certainly not blebs
%
%   p.numClasses - the number of classes (default is 2)
% 
%   p.classNames - a cell containing the names of the protrusions being 
%       clicked on, should be plural
%
% IMPORTANT NOTE: In some versions of Matlab, when a user attempts to 
% select a point on a mesh, points on both the front and the back of the 
% mesh may be selected. This code has been successfully tested in Matlab 
% 2017b and 2013b. 
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


% define parameters
availModes = {'restart', 'continue'};

% set the number of classes used by default
if ~isfield(p, 'numClasses'), p.numClasses = 2; end

% check some inputs
assert(ischar(p.nameOfClicker) && length(p.nameOfClicker) > 2, 'Invalid clicker name');
assert((ischar(p.mode) && ismember(p.mode, availModes)) | (isnumeric(p.mode) && min(p.mode > 0) && sum(mod(p.mode,1)) == 0), 'Invalid mode parameter');
assert(isfolder(p.mainDirectory), 'mainDirectory is not a directory');
assert(ischar(p.surfaceMode), 'surfaceMode is not a string');
assert(ischar(p.clickMode), 'surfaceMode is not a string');
assert((isscalar(p.framesPerCell) && isnumeric(p.framesPerCell) && p.framesPerCell > 0 && mod(p.framesPerCell,1) == 0), 'Invalid framesPerCell parameter');
assert((isscalar(p.numClasses) && isnumeric(p.numClasses) && p.numClasses > 0 && mod(p.numClasses,1) == 0), 'Invalid numClasses parameter');
assert(iscell(p.classNames) && length(p.classNames) == p.numClasses-1, 'Invalid classNames parameter');
if p.numClasses > 2, assert(strcmp(p.clickMode, 'clickOnCertain'), 'For more than 2 classes, clickMode must be set to clickOnCertain'); end

% iterate through the cells
for c = 1:length(p.cellsList)
    
    disp(['Cell ' num2str(c) ':  ' p.cellsList{c}]);
    
    % close any figures
    close all
    
    % try to load the MovieData object
    try 
        mdName = dir(fullfile(p.mainDirectory, p.cellsList{c}, '*.mat'));
        load(fullfile(p.mainDirectory, p.cellsList{c}, mdName.name));
    catch
        disp('The provided path is not the path to a Matlab variable');
    end
    sanityCheck(MD);
    
    % setup a directory to save data in
    savePath = fullfile(p.mainDirectory, p.cellsList{c}, 'TrainingData', p.nameOfClicker);
    if ~isfolder(savePath)
        mkdirRobust(savePath)
    else
        disp('Warning! A directory has already been created for this clicker.'); 

        % warn the user if any mode except continue is selected
        if ~strcmp(p.mode, 'continue')
            disp(['Warning! Running in ' p.mode ' mode. Previous validations may be overwritten.']); 
        end
        
    end
    
    % load variables if available
    if ~isempty(dir(fullfile(savePath, 'blebLocs.mat'))) 
        load(fullfile(savePath,'blebLocs.mat')); 
        
        % if the framesPerCell parameter does not match the loaded variables sizes, nix the saved variables
        if p.framesPerCell ~= length(frameIndex) || p.framesPerCell ~= length(locations)
            
            chanIndex = NaN(1,p.framesPerCell);
            frameIndex = NaN(1,p.framesPerCell);
            locations = cell(1,p.framesPerCell);
        end
        
    else
        chanIndex = NaN(1,p.framesPerCell);
        frameIndex = NaN(1,p.framesPerCell);
        locations = cell(1,p.framesPerCell);
    end

    % select frames to analyze
    timeFrames = floor(MD.nFrames_/p.framesPerCell);
    frames = 1:timeFrames:(timeFrames*p.framesPerCell+1);
    frames = frames(1:p.framesPerCell); 
    
    % setup variable paths
    analysisPath = fullfile(p.mainDirectory, p.cellsList{c}, 'Morphology', 'Analysis');
    surfacePath = [analysisPath filesep 'Mesh' filesep 'ch1'];
    surfaceSegmentPath = [analysisPath filesep 'SurfaceSegment' filesep 'ch1'];
    surfaceSegmentPatchMergePath = [analysisPath filesep 'PatchMerge'];
    
    % determine the channel to use
    meshProcessIndex = MD.packages_{1}.getProcessIndexByName('Mesh3DProcess');
    chan = MD.packages_{1}.processes_{meshProcessIndex}.funParams_.channels(1);
    if strcmp(chan, 'a'), chan = 1; end
        
    % iterate though the frames
    for f = 1:length(frames) 
        
        % for continue mode, check if this frame has already been analyzed
        if p.numClasses == 2
            if strcmp(p.mode, 'continue') && ~isnan(frameIndex(f)) && strcmp(p.clickMode, 'clickOnProtrusions') % && (size(locations{f}, 1) > 5 || size(locations{f}.blebs, 1) > 5) % remove the last condition for general use!!!
                continue
            elseif strcmp(p.mode, 'continue') && ~isnan(frameIndex(f)) && strcmp(p.clickMode, 'clickOnNotProtrusions') % && size(locations{f}.notBlebs, 1) > 5  % remove the last condition for general use!!!
                continue
            elseif strcmp(p.mode, 'continue') && ~isnan(frameIndex(f)) && strcmp(p.clickMode, 'clickOnCertain') && (size(locations{f}.blebs, 1) + size(locations{f}.notBlebs, 1)) > 5  % remove the last condition for general use!!!
                continue
            elseif isnumeric(p.mode) && ~max(ismember(frames(f), p.mode))
                continue
            end
        elseif p.numClasses > 2
            if strcmp(p.mode, 'continue') && ~isnan(frameIndex(f)) && (sum(cellfun(@(x) size(x, 1), locations{f}.protrusions(1:p.numClasses-1))) + size(locations{f}.notProtrusions, 1)) > 5  % remove the last condition for general use!!!
                continue
            elseif isnumeric(p.mode) && ~max(ismember(frames(f), p.mode))
                continue
            end
        end
        
        disp(['Frame ' num2str(f) ' of ' num2str(length(frames)) ';  frameIndex ' num2str(frames(f))]);
            
        % load the mesh and surfaceImage
        sStruct = load(fullfile(surfacePath, sprintf('surface_%i_%i.mat', chan, frames(f))));
        siStruct = load(fullfile(surfacePath, ['imageSurface_' num2str(chan) '_' num2str(frames(f)) '.mat']));
        
        % set the surface color
        if strcmp(p.surfaceMode, 'curvature')
            cStruct = load(fullfile(surfacePath, sprintf('meanCurvature_%i_%i.mat', chan, frames(f))));
            meshColor = cStruct.meanCurvature*(-1000/MD.pixelSize_);
            cmap = flipud(makeColormap('div_rwb', 1024));
            climits = [-1.5 1.5];
        elseif  strcmp(p.surfaceMode, 'surfaceSegment')
            sSStruct = load(fullfile(surfaceSegmentPath, sprintf('surfaceSegment_%i_%i.mat', chan, frames(f))));
            nStruct = load(fullfile(surfacePath, sprintf('neighbors_%i_%i.mat', chan, frames(f))));
            onBoundary = findBoundaryFaces(sSStruct.surfaceSegment, nStruct.neighbors, 'double');
            meshColor = ones(size(sStruct.surface.faces,1),1);
            meshColor(onBoundary==1) = 0; % on the boundary
            cmap = [0.2, 0.2, 0.2; 0.6,0.6,1.0];
            climits = [0 1];
       elseif  strcmp(p.surfaceMode, 'surfaceSegmentPatchMerge')
            sSStruct = load(fullfile(surfaceSegmentPatchMergePath, sprintf('surfaceSegment_%i_%i.mat', chan, frames(f))));
            nStruct = load(fullfile(surfacePath, sprintf('neighbors_%i_%i.mat', chan, frames(f))));
            onBoundary = findBoundaryFaces(sSStruct.surfaceSegmentPatchMerge, nStruct.neighbors, 'double');
            meshColor = ones(size(sStruct.surface.faces,1),1);
            meshColor(onBoundary==1) = 0; % on the boundary
            cmap = [0.2, 0.2, 0.2; 0.6,0.6,1.0];
            climits = [0 1];
        else % plot a blank surface
            meshColor = ones*size(sStruct.surface.faces,1);
            cmap = [0.5,0.5,1];
            climits = [0 Inf];
        end
        
        % run the clicker
        disp('   Please click on locations and press enter')
        disp('   Press "n" to go to the next cell, frame, or protrusion category')
        disp('   Rotate and zoom in on the cell using the buttons (which may be hidden) above the cell')
        disp(' ');
        if p.numClasses > 2
            for i = 1:p.numClasses-1
                disp(['   Click on locations that are certainly ' p.classNames{i}]);   
                meshPointsProtrusions{i} = clickMeshPoints(sStruct.surface, siStruct.imageSurface, meshColor, cmap, climits);
            end
            disp('   Click on locations that are certainly not protrusions');   
            meshPointsNotProtrusions = clickMeshPoints(sStruct.surface, siStruct.imageSurface, meshColor, cmap, climits);
        else % if there are only two classes
            if strcmp(p.clickMode, 'clickOnCertain')
                disp(['   Click on locations that are certainly ' p.classNames{1}]);   
                meshPointsBlebs = clickMeshPoints(sStruct.surface, siStruct.imageSurface, meshColor, cmap, climits);
                disp(['   Click on locations that are certainly not ' p.classNames{1}]);    
                meshPointsNotBlebs = clickMeshPoints(sStruct.surface, siStruct.imageSurface, meshColor, cmap, climits);
            elseif strcmp(p.clickMode, 'clickOnNotProtrusions')
                disp(['   Click on locations that are certainly not ' p.classNames{1}]);  
                meshPoints = clickMeshPoints(sStruct.surface, siStruct.imageSurface, meshColor, cmap, climits);
            else 
                disp(['   Click on locations that are certainly ' p.classNames{1}]);  
                meshPoints = clickMeshPoints(sStruct.surface, siStruct.imageSurface, meshColor, cmap, climits);
            end
        end
    
        % save the data
        if p.numClasses > 2  % more than two classes
           for i = 1:p.numClasses-1
               locations{f}.protrusions{i} = meshPointsProtrusions{i};
           end
            locations{f}.notProtrusions = meshPointsNotProtrusions;
        else  % two classes
            if strcmp(p.clickMode, 'clickOnNotProtrusions')
                locations{f}.notBlebs = meshPoints;   
            elseif strcmp(p.clickMode, 'clickOnCertain')
                locations{f}.blebs = meshPointsBlebs;
                locations{f}.notBlebs = meshPointsNotBlebs;
            else 
                locations{f}.blebs = meshPoints;
            end
        end
        frameIndex(f) = frames(f);
        chanIndex(f) = chan;
        pClick = p;
        save(fullfile(savePath,'blebLocs.mat'), 'locations', 'frameIndex', 'pClick')

    end
end