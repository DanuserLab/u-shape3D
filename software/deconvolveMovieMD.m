function deconvolveMovieMD(processOrMovieData, varargin)

% deconvolveMovieMD - deconvolves a MovieData object
%
%% INPUTS:
%
% processOrMovieData - a MovieData object or process that will be deconvolved
%
% p.OutputDirectory - directory where the deconvolved images will be saved
%
% p.chanList     - a list of the channels that will be analyzed 
% 
% p.deconMode       - type of deconvolution performed
%    'weiner'       - weiner deconvolution
%    'richLucy'     - Richardson-Lucy deconvolution
%    'blind'        - blind deconvolution   
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
% p.apodizeRL       - set to to 1 to apodize the Richardson-Lucy deconvolution
%
% p.saveNotApodized - set to 1, to save a non-apodized image (will only
%                     save in RL mode if apodization is turned on)
%
% p.pathDeconPSF    - the path of the saved psf for deconvolution 
%                     (see note below)
%
% p.pathApoPSF      - the path of the saved psf for apodization 
%                     (see note below)
%
% p.usePhotobleach  - set to 1 to load photobleach corrected images
%
% Note: the PSF must be saved in a .mat file at the path specified by 
% pathPSF.  The PSF is assumed to be a variable named PSF whose dimensions
% are in the order (x,y,z). maxOTF, the second largest OTF value in the fft 
% of the full size PSF, is also assumed to be saved in this mat file.
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


% Define additional parameters 
% segmentation parameters (only used if measureWeiner is enabled) 
% These are hardcoded but you probably don't want to change them.
imageBlurWeiner = 1; % the standard deviation in pixels of the gaussian that the image is blurred with prior to segmentation
morphRadiusErode = 3; %5 shrinks the estimated boundary by this number of pixels before measuring the mean signal
morphRadiusDilate = 10; %5 expands the estimated boundary by this number of pixels before measuring the noise variance %20

% save parameters
imageMultiply = 400; % multiply the deconvolved image by a number to improve the dynamic range of the saved images

%% Check input
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

%% Configure Paths
% configure input paths
photoDir = [MD.outputDirectory_ filesep 'Morphology' filesep 'Photobleach']; % always defined for the sake of the parfor
inFilePaths = cell(1, numel(MD.channels_));
for j = p.chanList
    inFilePaths{1,j} = MD.getChannel(j).channelPath_;
    inFilePaths{2,j} = [photoDir]; % filesep 'ch' num2str(i)]; % where is photobleach process?
end
process.setInFilePaths(inFilePaths);
if p.usePhotobleach
    assert(isfolder(photoDir), 'usePhotobleach is enabled but there are no photobleaching corrected images');
end

% configure output paths
imageSaveDir = p.OutputDirectory;
parameterSaveDir = [p.OutputDirectory filesep '..' filesep 'Analysis' filesep 'Parameters'];
outFilePaths = cell(5, numel(MD.channels_));
for i = p.chanList    
    outFilePaths{1,i} = [imageSaveDir filesep 'ch' num2str(i)];
    outFilePaths{2,i} = [parameterSaveDir filesep 'ch' num2str(i)];
    %mkClrDir(outFilePaths{1,i});
    mkdirRobust(outFilePaths{1,i});
    if ~isfolder(outFilePaths{2,i}), mkdirRobust(outFilePaths{2,i}); end
end
process.setOutFilePaths(outFilePaths);


%% Deconvolve
if ~isfield(p,'preLoadPSF') % (for the GUI)
    % check that the deconPSF path contains a varible named PSF
    if isempty(whos('-file', p.pathDeconPSF,'PSF'))
        error(['PSF must be a Matlab variable saved in ' p.pathDeconPSF])
    end

    % check that the PSF path contains a varible named maxOTF
    if isempty(whos('-file', p.pathDeconPSF,'maxOTF'))
        error(['maxOTF must be a Matlab variable saved in ' p.pathDeconPSF])
    end

    % load the deconPSF (point spread function)
    disp('  Loading the PSF')
    data = load(p.pathDeconPSF);
    deconPSF = data.PSF; 
    maxOTF = data.maxOTF; 

    if isfield(p,'pathApoPSF') && ~isempty(p.pathApoPSF) 
        % check that the apoPSF path contains a varible named PSF
        if isempty(whos('-file', p.pathApoPSF,'PSF'))
            error(['PSF must be a Matlab variable saved in ' p.pathApoPSF])
        end
    
        % load the deconPSF (point spread function)
        data = load(p.pathApoPSF);
        apoPSF = data.PSF; 
    else
        apoPSF = [];
    end

else
   
   deconPSF = p.preLoadPSF.PSF;
   maxOTF = p.preLoadPSF.maxOTF; 
   rmfield('PSF',p.preLoadPSF);
   rmfield('maxOTF',p.preLoadSF);

end

% deconvolve the image
weinerEstimateList = cell(numel(p.chanList),1);
parfor c = p.chanList % this is awkward, why not change the called files?
    p_tmp = p; 
    p_tmp.chanList = c;
    p_tmp = splitPerChannelParams(p_tmp, c);
    switch p_tmp.deconMode
        case 'weiner'
            weinerEstimateList{c} = weinerDeconvolveFull(MD, deconPSF, apoPSF, maxOTF, imageBlurWeiner, morphRadiusErode, morphRadiusDilate, imageMultiply, p_tmp, photoDir, outFilePaths{1,c});
        case 'richLucy'
            richLucyDeconvolveFull(MD, deconPSF, apoPSF, maxOTF, 0.99, p_tmp, photoDir, outFilePaths{1,c}, 0);
        case 'blind'
            richLucyDeconvolveFull(MD, deconPSF, apoPSF, maxOTF, 0.99, p_tmp, photoDir, outFilePaths{1,c}, 1);
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