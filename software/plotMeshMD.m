function [meshHandle, figHandle] = plotMeshMD(directoryMD, varargin)

% plotMeshMD - plots a 3D rendering of a surface image (requires that the mesh process have been run)
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
% directoryMD      - a MovieData object or a path to a MovieData object
%
% surfaceMode      - (optional) (default: blank)
%  'blank': draw a gray surface
%  'curvature': draw a surface colored by curvature
%  'curvatureWatersheds': the raw watershed segmentation of curvature
%  'curvatureSpillDepth': draw a surface colored by curvature segmentation with only spill depth merging (non-blebs are gray)
%  'surfaceSegment': draw a surface colored by segmention
%  'surfaceSegmentPreLocal': draw a surface colored by pre-local surface segmentation, will only run if the surface was locally segmented
%  'surfaceSegmentPatchMerge': draw a surface colored by segmention after patch merging
%  'surfaceSegmentInterTriangle': draw a surface colored by intermediate surface segmentation, triangle (data only saved for the first frame)
%  'surfaceSegmentInterLOS': draw a surface colored by intermediate surface segmentation, LOS (data only saved for the first frame)
%  'protrusions': draw a surface colored by protrusion segmentation (non-protrusions are gray)
%  'protrusionsType': draw a surface colored by protrusion segmentation, with each type of protrusion a seperate color (non-protrusions are gray)
%  'SVMscore': draw a surface colored by the SVM score
%  'SVMscoreThree': draw a surface colored by the SVM score with the SVM score binned into three levels
%  'clickedOn': draw a surface colored by patches identified as certainly blebs/certainly non-blebs
%  'blebsShrunk': draw a surface colored by shrunken blebs (non-blebs are gray)
%  'blebsTracked': draw a surface colored by tracked blebs
%  'blebsTrackedOverlap': draw a surface colored by temporally overlapped blebs
%  'motion': draw a surface colored by motion
%  'motionFowards': draw a surface colored by forwards motion
%  'intensity': draw a surface colored by intensity
%  'intensityVertex': draw a surface colored by intensity based on vertices
%  'motifsClustered': draw a surface colored by motif clustering
%  'patchesClustered': draw a surface colored by patch clustering
%
% frame            - (optional) the index of the frame for which a mesh 
%                  will be plotted (default: 1)
%
% chan             - (optional) the index of the channel for which data 
%                  will be plotted. The defult is the lowest channel index
%                  for which a saved surfaceImage or mesh exists.
%
% meshMode         - (optional) (default: 'surfaceImage')
%  'surfaceImage': draw an isosurface of the surfaceImage saved by the mesh
%                  process (lighting is correct but the mesh is wrong)
%  'actualMesh':   draw the mesh saved by the mesh process (lighting is 
%                  wrong but the mesh is correct)
%
% meshAlpha       - (optional) (default: 1) the transparency of the mesh
%
% surfaceChannel  - (optional) (default: 'self')
%                 index of the channel from which the mesh will be plotted
%  'self':        uses the index found in chan
%  integer:       a scaler integer specifying a channel
%
% setView          - (optional) (default: [0,90]) two angles in a vector 
%                  specifying the azimuth and elevation of the view angle. 
%                  XY is [0,90], XZ is [0,90], and YZ is [90,0].
%
% makeRotation     - (optional) rotate the mesh and save the rotation as a
%                  movie (defualt is 0)
% 
% rotSavePath      - (optional) the directory where the rotation will be
%                  saved (default:'Analysis/Movies/rotate_(surfaceMode)_(chan)_(frame)/')
%
% makeMovie        - (optional) make a movie that includes every time point
%                  (defualt is 0)
% 
% movieSavePath    - (optional) the directory where the movie will be saved
%                  (default: 'Analysis/Movies/(surfaceMode)_(chan)/')
%
% daeSaveName      - (optional) the name of the dae file to be saved
%                  (default: 'Analysis/Movies/(surfaceMode)_(chan)/')
% daeSavePathMain  - path for saving daeSaveName files
%
% makeColladaDae   - (optional) save the mesh as a .dae file (default is 0)
%
% surfaceSegmentInterIter - (optional) the number of the intermediate surface segmentation iteration to plot
%
% useBlackBkg      - (optional) Render Mesh with black figure background (default is 1)

%% Set parameters
colorKey = 839; % ideally a large prime number (greater than the number of watershed regions)
% (From the patch label, the colormap, and this key you can reconstruct the 
% patch color and so use the color for other sorts of visualizations.)

 
%% Parse inputs
ip = inputParser;
ip.KeepUnmatched = true;
ip.PartialMatching = false;
addRequired(ip, 'dirMD', @(x) (ischar(x) || isa(x,'MovieData') || isa(x,'Process')));
addParameter(ip, 'surfaceMode', 'blank', @ischar);
addParameter(ip, 'frame', 1, @(x) (isscalar(x) && x>0));
addParameter(ip, 'chan', 0, @(x) (isscalar(x) && x>=0));
% addParameter(ip, 'ChannelIndex', []);
addParameter(ip, 'meshMode', 'actualMesh', @ischar);
addParameter(ip, 'surfaceChannel', 'self', @(x) (ischar(x)  || (isscalar(x) && isnumeric(x) && x>0)));
addParameter(ip, 'setView', [0,90], @(x) (isnumeric(x) && length(x)==2));
addParameter(ip, 'makeRotation', 0, @(x) (x==0 || x==1));
addParameter(ip, 'rotSavePath', '', @ischar);
addParameter(ip, 'makeMovie', 0, @(x) (x==0 || x==1));
addParameter(ip, 'movieSavePath', '', @ischar);
addParameter(ip, 'daeSaveName', '', @ischar);
addParameter(ip, 'meshAlpha', 1,  @(x) (isscalar(x) && x>0 && x<=1));
addParameter(ip, 'makeColladaDae', 0, @(x) (x==0 || x==1));
addParameter(ip, 'daeSavePathMain', '',@ischar);
addParameter(ip, 'makeMovieAVI', 0, @(x) (x==0 || x==1));
addParameter(ip, 'movieAVISavePath', '', @ischar);
addParameter(ip, 'figHandleIn',[],@isgraphics);
addParameter(ip, 'useBlackBkg',1, @(x) (x==0 || x==1)); 
addParameter(ip, 'surfaceSegmentInterIter', 1, @(x) (isscalar(x) && x>0));
ip.parse(directoryMD, varargin{:});
p = ip.Results;


progressText(0,'PLEASE WAIT ...Generating Custom Rendering....','plotMeshMD');

% check that the inputted surfaceMode is valid
surfaceModes = {'blank', 'curvature', 'curvatureWatersheds', 'curvatureSpillDepth', ...
    'surfaceSegment', 'surfaceSegmentPreLocal', 'surfaceSegmentPatchMerge', ...
    'surfaceSegmentInterTriangle', 'surfaceSegmentInterLOS', 'protrusions', ...
    'protrusionsType',  'SVMscore', 'SVMscoreThree', 'clickedOn', ...
    'blebsShrunk', 'blebsTracked', 'blebsTrackedOverlap', 'motion', ...
    'motionForwards', 'intensity','intensityVertex', 'motifsClustered', 'patchesClustered'};
assert(max(strcmp(p.surfaceMode,surfaceModes)), [p.surfaceMode ' is not a valid surfaceMode']);

% check that the inputted meshMode is valid
meshModes = {'surfaceImage', 'actualMesh'};
assert(max(strcmp(p.meshMode,meshModes)), [p.meshMode ' is not a valid meshMode']);

% try to load the MovieData object
if isa(p.dirMD, 'MovieData')
    MD = p.dirMD;
elseif isa(p.dirMD, 'Process')
    MD = p.dirMD.owner_;
else
    try 
        files = dir(fullfile(p.dirMD, '*.mat'));
        if length(files) == 1
            load(fullfile(p.dirMD, files(1).name));
        else
            disp(['The following directory contains multiple Matlab variables: ' p.dirMD]);
        end
    catch
        disp(['The following directory does not contain a Matlab variable: ' p.dirMD]);
    end
end


% check that provided channel is a valid channel index 
% (if 0 then a channel wasn't provided and will be found later)
assert(p.chan==0 || p.chan<=(length(MD.channels_)), 'channel must be an index of a MovieData channel')

% set the surfaceChannel parameter
if ischar(p.surfaceChannel) && strcmp(p.surfaceChannel, 'self')
    p.surfaceChannel = p.chan;
end


%% Load data
% set the path where the mesh is stored
meshProc = MD.findProcessTag('Mesh3DProcess',false, false,'tag',false,'last');
if p.surfaceChannel == 0
   meshPath = meshProc.outFilePaths_{1,1};
   intensityPath = meshProc.outFilePaths_{4,1}; % summary stats 
else
   meshPath = meshProc.outFilePaths_{1,p.surfaceChannel}; 
   intensityPath = meshProc.outFilePaths_{4,p.surfaceChannel}; % summary stats 
end

% Take care to avoid missing data for motion analysis.
movieStartFrame = 1;
movieEndFrame = MD.nFrames_;
if strcmp(p.surfaceMode, 'motion')
    motionProc = MD.findProcessTag('MeshMotion3DProcess',false, false,'tag',false,'last');
    motionMode = motionProc.funParams_.motionMode;
    if strcmp(motionMode,'backwards') 
        if p.frame == 1
            warning('Setting frame number to 2 , no data exists for 1st frame in (backward) motion analysis');
            p.frame = 2;
        end
        movieStartFrame = 2;
        movieEndFrame = MD.nFrames_;
    elseif strcmp(motionMode,'forwards') 
        if p.frame == MD.nFrames_
            warning('Setting frame number to N-1 , no data exists for last frame in (forward) motion analysis');
            p.frame = MD.nFrames_ - 1;
        end
        movieStartFrame = 1;
        movieEndFrame = MD.nFrames_ - 1;
    end
end



% if needed load the intensity levels to generate the isosurface
if strcmp(p.meshMode, 'surfaceImage')
    levels = load(fullfile(intensityPath, 'intensityLevels.mat'));
end

% if the user provided a channel index, try loading that channel
imageName = 'imageSurface_%i_%i.mat';
surfaceName = 'surface_%i_%i.mat';
if p.surfaceChannel > 0   
    
    % check if the image data exists and if it does load it
    imagePath = fullfile(meshPath, sprintf(imageName, p.surfaceChannel, p.frame));
    assert(~isempty(dir(imagePath)), ['Invalid variable path: ' imagePath]);
    iStruct = load(imagePath);
    
    % load the surface mesh if needed
    if strcmp(p.meshMode, 'actualMesh')
        surfacePath = fullfile(meshPath, sprintf(surfaceName, p.surfaceChannel, p.frame)); 
        assert(~isempty(dir(surfacePath)), ['Invalid variable path: ' surfacePath]);
        mStruct = load(surfacePath);
    end
    
else % if the user did not provide a channel index just start going through the channels looking for a surfaceImage
    for c = 1:length(MD.channels_)
        imagePath = fullfile(meshPath, sprintf(imageName, c, p.frame));
        if ~isempty(dir(imagePath))
            
            % load the surfaceImage
            iStruct = load(imagePath);
            
            % load the surface mesh if wanted
            if strcmp(p.meshMode, 'actualMesh') 
                surfacePath = fullfile(meshPath, sprintf(surfaceName, c, p.frame)); 
                assert(~isempty(dir(surfacePath)), 'There is no mesh to accompany the found surfaceImage.');
                mStruct = load(surfacePath);
            end
            
            % stop looking through the channels
            p.chan = c;
            p.surfaceChannel = c;
            break
        end
    end
    
    % display an error if no surface was found in any channel
    if p.surfaceChannel == 0
        error('No surface was found');
    end
end
progressText(.25,'Generating Custom Rendering..Please wait...','plotMeshMD');

% make a directory to save a rotation movie in if needed 
if p.makeRotation == 1
    if isempty(p.rotSavePath)
        p.rotSavePath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Outputs' filesep ...
            'Movies' filesep p.surfaceMode '_rotate_' num2str(p.chan) '_' num2str(p.frame)];
    end
    if ~isdir(p.rotSavePath), system(['mkdir -p ' p.rotSavePath]); end
end

% make a directory to save a  movie of all the time points in if needed 
if p.makeMovie == 1
    if isempty(p.movieSavePath)
        p.movieSavePath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Outputs' filesep ...
            'Movies' filesep p.surfaceMode '_' num2str(p.chan)];
    end
    if ~isdir(p.movieSavePath), system(['mkdir -p ' p.movieSavePath]); end
end

% make a directory to save the dae file in if needed 
if p.makeColladaDae == 1 
    if isempty(p.daeSavePathMain)
        p.daeSavePathMain = [MD.outputDirectory_ filesep 'Morphology' filesep 'Outputs' filesep 'Collada'];
    end
    if ~isdir(p.daeSavePathMain), system(['mkdir -p ' p.daeSavePathMain]); end
    daeSavePathMain =  p.daeSavePathMain;
end

% make a directory to save the .avi movie file needed
if p.makeMovieAVI
    if isempty(p.movieAVISavePath)
        p.movieAVISavePath = [MD.outputDirectory_ filesep 'Morphology' filesep 'Outputs' filesep...
            'MoviesAVI' filesep p.surfaceMode '_' num2str(p.chan)];
    end
    if ~isdir(p.movieAVISavePath), system(['mkdir -p ' p.movieAVISavePath]); end
end


%% Plot the mesh

% determine the mesh that will be plotted 
if strcmp(p.meshMode,'surfaceImage')
    meshToPlot = isosurface(iStruct.imageSurface,levels.intensityLevels(p.surfaceChannel,p.frame));
elseif strcmp(p.meshMode,'actualMesh')
    meshToPlot = mStruct.surface;
end
image3D = iStruct.imageSurface;
progressText(.5,'Generating Custom Rendering..Please wait...','plotMeshMD');

% load the color of the surface
meshColor = loadMeshSurfaceColor(MD, p.surfaceMode, p.chan, p.frame, colorKey, p.surfaceSegmentInterIter);

% set the mesh's colormap
switch p.surfaceMode
    case 'blank'
        %cmap = [1 0.1 0];
        cmap = [0.6 0.6 0.6];
        climits = [0 Inf];
        
    case 'curvature'        
        cmap = flipud(makeColormap('div_rwb', 1024));
        %cmap = flipud(makeColormap('div_spectral', 1024));
        climits = [-1.5 1.5];
        %climits = [-2 2];
        
    case 'curvatureWatersheds'
        cmap = [0.6,0.6,0.6; flipud(makeColormap('div_spectral', 1024)).^2];
        climits = [0 Inf];
        
    case 'curvatureSpillDepth'
        cmap = [0.6,0.6,0.6; flipud(makeColormap('div_spectral', 1024)).^2];
        climits = [0 Inf];
        
    case 'surfaceSegment'
        cmap = [0.6,0.6,0.6; flipud(makeColormap('div_spectral', 1024)).^2];
        climits = [0 Inf];
        
    case 'surfaceSegmentPreLocal'
        cmap = [0.6,0.6,0.6; flipud(makeColormap('div_spectral', 1024)).^2];
        climits = [0 Inf];
        
    case 'surfaceSegmentPatchMerge'
        cmap = [0.6,0.6,0.6; flipud(makeColormap('div_spectral', 1024)).^2];
        climits = [0 Inf];
        
    case 'surfaceSegmentInterTriangle'
        cmap = [0.6,0.6,0.6; flipud(makeColormap('div_spectral', 1024)).^2];
        climits = [0 Inf];  
        
    case 'surfaceSegmentInterLOS'
        cmap = [0.6,0.6,0.6; flipud(makeColormap('div_spectral', 1024)).^2];
        climits = [0 Inf];       
        
    case 'protrusions'
        cmap = [0.6,0.6,0.6; flipud(makeColormap('div_spectral', 1024)).^2];
        climits = [0 Inf];
        
    case 'protrusionsType'
        cmap = [0.7,0.7,0.7; 64/255,224/255,208/256; 221/255,160/255,221/255];
        cmap = [0.6,0.6,0.6; 0.9,0.1,0.1; 0.1,0.3,0.6]; 
        climits = [0 Inf];
        
    case 'SVMscore'
        cmap = [0.6,0.6,0.6; flipud(makeColormap('div_pwg', 1024))];
        climits = [-1*max(abs(meshColor)) max(abs(meshColor))];  
        %climits = [-15 15];
        
   case 'SVMscoreThree'
        cmap = [0.6,0.6,0.6; makeColormap('div_pwg', 3)];
        climits = [min(meshColor) max(meshColor)]; 
        
   case 'clickedOn'
        cmap = [0.6,0.6,0.6; makeColormap('div_brwg', 3)];
        climits = [min(meshColor) max(meshColor)];  

    case 'blebsShrunk'
        cmap = [0.6,0.6,0.6; flipud(makeColormap('div_spectral', 1024))];
        climits = [0 Inf];
        
    case 'blebsTracked'
        cmap = [0.6,0.6,0.6; flipud(makeColormap('div_spectral', 1024))];
        climits = [0 Inf];
        
    case 'blebsTrackedOverlap'
        cmap = [0.6,0.6,0.6; flipud(makeColormap('div_spectral', 1024))];
        climits = [0 Inf];
        
    case 'motion'
        cmap = flipud(makeColormap('div_rwb', 1024)).^(1/2);
        %cmap = (flipud(makeColormap('div_ryb', 1024))).^(1/2);
        %climits = [prctile(faceIntensities.mean,3), prctile(faceIntensities.mean,97)];
        climits = [-1.5 1.5];   
        
    case 'motionForwards'
        cmap = flipud(makeColormap('div_rwb', 1024)).^(1/2);
        %cmap = (1-flipud(makeColormap('div_ryb', 1024))).^(1/2);
        %climits = [prctile(faceIntensities.mean,3), prctile(faceIntensities.mean,97)];
        climits = [-6 6]; 
        
    case 'intensity'
        %cmap = flipud(makeColormap('div_spectral', 1024)).^(1/2);
        %cmap = (flipud(makeColormap('div_ryb', 1024))).^(1/2);
        cmap = (flipud(makeColormap('div_ryb', 1024)));
        %climits = [prctile(meshColor,1), prctile(meshColor,99)];
        %climits = [0 2.2];
        climits = [0.4 1.6];
        %climits = [0.2 1.8];
        
    case 'intensityVertex'
         cmap = (flipud(makeColormap('seq_yor', 1024)));
         climits = [prctile(meshColor,1), prctile(meshColor,99)];
         
    case 'motifsClustered'
        %cmap = [0.6,0.6,0.6; makeColormap('div_spectral', 4)];
        %cmap = lines(6);
        %cmap(1,:) = [0.6, 0.6, 0.6];
        %cmap = [0.6,0.6,0.6; cmap(2:3,:); cmap(5:6,:)];
        cmap = [0.6,0.6,0.6; hsv(16)];
        climits = [0 16];
        
    case 'patchesClustered'
        %cmap = [0.6,0.6,0.6; makeColormap('div_spectral', 4)];
        cmap = [0.6,0.6,0.6; jet(2).^0.5];
        climits = [0 2];
    
    otherwise
        cmap = [0.4 0 0.4];
        climits = [0 Inf];
end

% render the mesh
if isempty(p.figHandleIn)
    figHandle = figure;
else
    figHandle = ancestor(p.figHandleIn,'figure','toplevel');
end
% figHandle.Tag = 'meshFigure';
if p.useBlackBkg
    figHandle.Color = [0, 0, 0];
end

meshHandle = [];
if max(meshColor) > 0
    [light_handle, meshHandle] = plotMeshFigure(image3D, meshToPlot, meshColor, cmap, climits, p.meshAlpha, 'figHandle', figHandle);
    % set the view
    view(p.setView(1), p.setView(2));
    material([0.40 .45 0.7 ])
end

progressText(.8,'Generating Custom Rendering...please wait','plotMeshMD');
progressText(1,'Generating Custom Rendering ... COMPLETED', 'plotMeshMD');
% save the mesh as a .dae file
if p.makeColladaDae == 1 && max(meshColor) > 0
     progressText(0,'Exporting to DAE .... please wait', 'Exporting to DAE');
    if isempty(p.daeSaveName)
        daeSavePath = [daeSavePathMain filesep p.surfaceMode '_' num2str(p.chan) '_' num2str(p.frame, '%05d') '.dae'];
    else
        daeSavePath = [daeSavePathMain filesep p.daeSaveName '.dae'];
    end
    % check if the intensity is calculated on mesh vertices
    if ~strcmp(p.surfaceMode, 'intensityVertex')
        vertexColorRGB = faceColorsToVertexColorsRGB(meshColor, meshToPlot, cmap, climits);
    else
        vertexColorRGB = meshColor;
    end
    progressText(0.75,'Exporting to DAE .... please wait', 'Exporting to DAE');
    saveDAEfile(image3D, meshToPlot, vertexColorRGB, cmap, climits, daeSavePath);
    progressText(1,'Exporting to DAE Complete', 'Exporting to DAE');
end

%% Save a rotation of the mesh as an image seqence
if p.makeRotation
    disp('Rotating the surface');
    if p.makeMovieAVI
        saveMeshRotation(light_handle, p.rotSavePath, 'movieAVISavePath', p.movieAVISavePath, 'setView', p.setView);
    else
        saveMeshRotation(light_handle, p.rotSavePath, 'setView', p.setView);
    end
end


%% Save the mesh in all frames of the movie as an image sequence
if p.makeMovie
    progressText(0,'Generating Movie for Custom Rendering','Making Movie');
    disp('Making a movie');
    
    % if the first frame as already been plotted save it
    frameName = 'frame%03d'; 
    movieframeSeq = 0;
    if p.frame == movieStartFrame
        sprintf(frameName, movieStartFrame);
        if ~strcmp(p.surfaceMode, 'motion')
            mesh_fig = ancestor(meshHandle,'figure','toplevel');
            if p.useBlackBkg
                figHandle.Color = [0, 0, 0];
            end
            % set the view
            view(p.setView(1), p.setView(2));
            material([0.40 .45 0.7 ])
            saveas(mesh_fig,fullfile(p.movieSavePath,sprintf(frameName,p.frame)), 'tiffn');
            if p.makeMovieAVI
                movieframeSeq = movieframeSeq + 1;
                movieFrames(movieframeSeq) = getframe(mesh_fig);
            end
        end
        movieStartFrame = movieStartFrame + 1;
    end

    % iterate through the remaining frames
    for f = movieStartFrame:movieEndFrame
        progressText(f/MD.nFrames_,'Generating Movie for Custom Rendering','Making Movie');
        % display progress
        disp('.');
        disp(['   frame ' num2str(f)]);
        
        % load the frame
        imagePath = fullfile(meshPath, sprintf(imageName, p.surfaceChannel, f));
        iStruct = load(imagePath);
        image3D = iStruct.imageSurface;
        
        % determine the mesh that will be plotted 
        if strcmp(p.meshMode,'surfaceImage')
            meshToPlot = isosurface(iStruct.imageSurface,levels.intensityLevels(p.surfaceChannel,f));
            
        elseif strcmp(p.meshMode,'actualMesh')
            surfacePath = fullfile(meshPath, sprintf(surfaceName, p.surfaceChannel, f)); 
            mStruct = load(surfacePath);
            meshToPlot = mStruct.surface;
        end
        
        % load the color of the surface
        meshColor = loadMeshSurfaceColor(MD, p.surfaceMode, p.chan, f, colorKey);
        
        % render the mesh
        [light_handle, mesh_handle] = plotMeshFigure(image3D, meshToPlot, meshColor, cmap, climits, p.meshAlpha, 'figHandle', figHandle);

        mesh_fig = ancestor(mesh_handle,'figure','toplevel');
        figure(figHandle)
        
        if p.useBlackBkg
            figHandle.Color = [0, 0, 0];
        end
        
        % set the view
        view(p.setView(1), p.setView(2));
        material([0.40 .45 0.7 ]);
        drawnow;
        
        if p.makeMovieAVI
            movieframeSeq = movieframeSeq + 1;
            movieFrames(movieframeSeq) = getframe(mesh_fig);
        end
        % save the image
        saveas(figHandle,fullfile(p.movieSavePath,sprintf(frameName,f)), 'tiffn');
        
        % save the mesh as a .dae file if wanted
        if p.makeColladaDae == 1
            progressText(0,'Exporting to DAE ', 'DAEout');
            if isempty(p.daeSaveName)
                daeSavePath = [daeSavePathMain filesep p.surfaceMode '_' num2str(p.chan) '_' num2str(f, '%05d') '.dae'];
            else
                daeSavePath = [daeSavePathMain filesep p.daeSaveName '_' num2str(f, '%05d') '.dae'];
            end
            % check if the intensity is calculated on mesh vertices
            if ~strcmp(p.surfaceMode, 'intensityVertex')
                vertexColorRGB = faceColorsToVertexColorsRGB(meshColor, meshToPlot, cmap, climits);
            else 
                vertexColorRGB = meshColor;
            end 
            progressText(0.5,'Exporting to DAE ', 'DAEout.');
            saveDAEfile(image3D, meshToPlot, vertexColorRGB, cmap, climits, daeSavePath);
            progressText(1,'Exporting to DAE complete', 'DAEout');
        end
    end
    if p.makeMovieAVI && MD.nFrames_ > 1
        v = VideoWriter([p.movieAVISavePath filesep 'MeshMovie_Ch' num2str(p.surfaceChannel) '_' ...
                         p.surfaceMode '_' ... 
                         num2str(p.setView(1)) 'az-' num2str(p.setView(2)) 'el.avi']);
        v.FrameRate = 10;
        open(v);
        writeVideo(v, movieFrames);
        close(v);    
    else
        warning('Not creating .avi movie file, only one frame.')
    end
end
