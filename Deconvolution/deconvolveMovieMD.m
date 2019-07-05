function deconvolveMovieMD(processOrMovieData, varargin)

% deconvolveMovieMD - deconvolves a MovieData object
%
%% INPUTS:
%
% processOrMovieData                - a MovieData object that will be deconvolved
%
% p.OutputDirectory - directory where the deconvolved images will be saved
%
% p.ologyList        - a list of the channels that will be analyzed 
% 
% p.deconMode       - type of deconvolution performed
%    'weiner'       - weiner deconvolution with apodization
%    'richLucy'     - Richardson-Lucy deconvolution with no damping
%
% p.weinerAuto      - 1 if the Weiner parameter is automatically calculated, 
%                     and 0 otherwise
%
% p.weiner          - the value of the weiner parameter. This is ignored if 
%                     weinerAuto is set to 1
% 
% p.apoHeight       - the value of the apodization height in the Weiner
%                     deconvolution
%
% p.richLucyIter    - number of iteration of the Richardson-lucy
%                     deconvolution performed
%
% p.pathPSF         - the path of the saved psf (see note below)
%
% p.usePhotobleach  - set to 1 to load photobleach corrected images
%
% Note: the PSF must be saved in a .mat file at the path specified by 
% pathPSF.  The PSF is assumed to be a variable named PSF whose dimensions
% are in the order (x,y,z). maxOTF, the second largest OTF value in the fft 
% of the full size PSF, is also assumed to be saved in this mat file.
% Meghan Driscoll 2016
% Updated by Andrew R. Jamieson July 2018
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


%Check input
ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('movieData', @(x) isa(x,'Process') && isa(x.getOwner(),'MovieData') || isa(x,'MovieData'));
ip.addOptional('paramsIn',[], @isstruct);
ip.addParameter('ProcessIndex',[],@isnumeric);
ip.parse(processOrMovieData,varargin{:});
paramsIn = ip.Results.paramsIn;

[MD, process] = getOwnerAndProcess(processOrMovieData,'Deconvolution3DProcess',true);
p = parseProcessParams(process, paramsIn);

% interpret the channels parameter
if ischar(p.channels) && strcmp(p.channels, 'all')
    p.chanList = 1:length(MD.channels_);
elseif isnumeric(p.channels)
    p.chanList = p.channels;
else
    p.chanList = p.ChannelIndex;
end
p = rmfield(p, 'channels');

% ============= Configure InputPaths. ================
% check that photobleach corrected images exist 
photoDir = [MD.outputDirectory_ filesep 'Morphology' filesep 'Photobleach']; % always defined for the sake of the parfor


inFilePaths = cell(1, numel(MD.channels_));
for j = p.chanList
    inFilePaths{1,j} = MD.getChannel(j).channelPath_;
    inFilePaths{2,j} = [photoDir]; % filesep 'ch' num2str(i)]; % where is photobleach process?
end
process.setInFilePaths(inFilePaths);
% ============= ==================== ================

if p.usePhotobleach
    assert(isfolder(photoDir), 'usePhotobleach is enabled but there are no photobleaching corrected images');
end

% create a directory to save images in
imageSaveDir = p.OutputDirectory;
% save the parameters used
parameterSaveDir = [p.OutputDirectory filesep '..' filesep 'Analysis' filesep 'Parameters'];
% ============= Configure OutputPaths. ================
outFilePaths = cell(5, numel(MD.channels_));
for i = p.chanList    
    outFilePaths{1,i} = [imageSaveDir filesep 'ch' num2str(i)];
    outFilePaths{2,i} = [parameterSaveDir filesep 'ch' num2str(i)];
    mkClrDir(outFilePaths{1,i});
    if ~isfolder(outFilePaths{2,i}), mkdirRobust(outFilePaths{2,i}); end
end
process.setOutFilePaths(outFilePaths);
% ===

%% Define additional parameters 
% segmentation parameters (only used if measureWeiner is enabled) 
% These are hardcoded but you probably don't want to change them.
imageBlurWeiner = 1; % the standard deviation in pixels of the gaussian that the image is blurred with prior to segmentation
morphRadiusErode = 3; %5 shrinks the estimated boundary by this number of pixels before measuring the mean signal
morphRadiusDilate = 10; %5 expands the estimated boundary by this number of pixels before measuring the noise variance %20

% save parameters
imageMultiply = 400; % multiply the deconvolved image by a number to improve the dynamic range of the saved images

if ~isfield(p,'preLoadPSF')
    % check that the PSF path contains a varible named PSF
    if isempty(whos('-file', p.pathPSF,'PSF'))
        error(['PSF must be a Matlab variable saved in ' p.pathPSF])
    end

    % check that the PSF path contains a varible named maxOTF
    if isempty(whos('-file', p.pathPSF,'maxOTF'))
        error(['maxOTF must be a Matlab variable saved in ' p.pathPSF])
    end

    % load the PSF (point spread function)
%     tic;
    disp('  Loading the PSF')
    data = load(p.pathPSF); % use data.PSF, etc. to work with parfor
    PSF = data.PSF; 
    maxOTF = data.maxOTF; 
%     toc
else
   
   PSF = p.preLoadPSF.PSF;
   maxOTF = p.preLoadPSF.maxOTF; 
   rmfield('PSF',p.preLoadPSF);
   rmfield('maxOTF',p.preLoadSF);
end
% =================================================

% deconvolve the image
% parffor c = p.chanList
weinerEstimateList = cell(numel(p.chanList),1);
parfor c = p.chanList
    p_tmp = p;
    p_tmp.chanList = c;
    p_tmp = splitPerChannelParams(p_tmp, c);
    switch p_tmp.deconMode
        case 'weiner'
            weinerEstimateList{c} = weinerDeconvolveFull(MD, PSF, maxOTF, imageBlurWeiner, morphRadiusErode, morphRadiusDilate, imageMultiply, p_tmp, photoDir, outFilePaths{1,c});
        case 'richLucy'
            richLucyDeconvolveFull(MD, PSF, 1/10, p_tmp, photoDir, outFilePaths{1,c});
        otherwise
            error([p_tmp.deconMode ' is not an allowed decon mode']);
    end
end



if p.weinerAuto == 1
    save(fullfile(parameterSaveDir, 'deconParameters.mat'), 'p', 'weinerEstimateList', 'imageBlurWeiner', 'morphRadiusErode', 'morphRadiusDilate');
else 
    save(fullfile(parameterSaveDir, 'deconParameters.mat'), 'p');
end
MD.save();