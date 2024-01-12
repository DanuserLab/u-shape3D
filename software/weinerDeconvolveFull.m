function weinerEstimateList = weinerDeconvolveFull(MD, deconPSF, apoPSF, maxOTF, imageBlurWeiner, morphRadiusErode, morphRadiusDilate, imageMultiply, p, photoDir, imageSaveDir)

% weinerDeconvolveFull - performs weiner deconvolution and apodization, also tries to calculate the weiner parameter
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

% find the image size
imageSize = [MD.imSize_(1,1), MD.imSize_(1,2), MD.zSize_(1,1)];

% calculate the OTFs (optical transfer function)
disp('  Calculating the OTF')
[deconOTF, newImageSize] = calculateSmallOTF(deconPSF, imageSize); clear deconPSF;


if ~isempty(apoPSF)
	[apoOTF, newImageSize] = calculateSmallOTF(apoPSF, imageSize); clear apoPSF;
	% calculate an apodization filter
	disp('  Calculating the apodization filter (using apoPSF)')
	apodizeFilter = makeApodizationFilter(apoOTF, maxOTF, p.apoHeight); clear apoOTF
else
	disp('  Calculating the apodization filter (using deconPSF)')
	apodizeFilter = makeApodizationFilter(deconOTF, maxOTF, p.apoHeight);	
end

% Weiner deconvolve the images
disp(['  Deconvolving images: ' num2str(MD.nFrames_) ' time points'])

% make structuring elements if needed for automatic Weiner parameter calculation
weinerEstimateList = [];
if p.weinerAuto == 1
    sphereErodeSE = makeSphere3D(morphRadiusErode);
    sphereDilateSE = makeSphere3D(morphRadiusDilate);
end   

% iterate through the images
for t = 1:MD.nFrames_    
    for c = p.chanList
        
        % display progress
        disp(['     image ' num2str(t) ' (channel ' num2str(c) ')'])
    
        % load the frame
        if p.usePhotobleach
            imageName = sprintf('photo_%d_%d.tif', c, t);
            image3D = load3DImage(photoDir, imageName); 
        else
            image3D = im2double(MD.getChannel(c).loadStack(t));
        end
        
        % crop the image if needed
        if min(newImageSize==imageSize) == 0
            originImage = ceil((imageSize+ones(1,3))/2); % (for even sizes the origin occurs above the center, i.e. the origin of an image with size 4x4 occurs at (3,3) )
            image3D = image3D((originImage(1)-ceil((newImageSize(1)-1)/2)):(originImage(1)+floor((newImageSize(1)-1)/2)), ...
                (originImage(2)-ceil((newImageSize(2)-1)/2)):(originImage(2)+floor((newImageSize(2)-1)/2)), ...
                (originImage(3)-ceil((newImageSize(3)-1)/2)):(originImage(3)+floor((newImageSize(3)-1)/2)));
        end
        
        % estimate the Weiner parameter if desired
        if p.weinerAuto == 1
            [signalMean, signalMax, ~, backgroundMean, backgroundSTD] = cellSignalAndBackground(image3D, imageBlurWeiner, sphereErodeSE, sphereDilateSE);
            weinerEstimate = backgroundSTD/(signalMean-backgroundMean);
            %weinerEstimate = backgroundSTD/(signalMax-backgroundMean);
            weinerEstimateList = [weinerEstimateList, weinerEstimate];
        else
            weinerEstimate = p.weiner;
        end
        
        % deconvolve the image
        [image3D, image3DnotApodized] = weinerDeconvolve(image3D, deconOTF, weinerEstimate, apodizeFilter, p.saveNotApodized);
        
        % this is annoying
        image3D = imageMultiply*image3D;
        
        % convert the image to a 16-bit integer
        image3D = uint16((2^16-1)*image3D);

        % display warnings if the image dynamic range is incorrect
        if max(image3D(:)) < 100
            disp(['The maximum image value, ' num2str(max(image3D(:))) ', is low.'])
        elseif max(image3D(:)) == 2^16-1
            disp('The image brightness is saturated.')
        end
        
        % save the deconvolved image
        imageName = ['decon_' num2str(c) '_' num2str(t) '.tif'];
        imagePath = fullfile(imageSaveDir, imageName);
        save3DImage(image3D, imagePath);
        
        % save a non-apodized version of the deconvolved image
        if p.saveNotApodized
            image3DnotApodized = imageMultiply*image3DnotApodized;
            image3DnotApodized = uint16((2^16-1)*image3DnotApodized);
            imageName = ['deconNotApodized_' num2str(c) '_' num2str(t) '.tif'];
            imagePath = fullfile(imageSaveDir, imageName);
            save3DImage(image3DnotApodized, imagePath);
        end
        
    end
end