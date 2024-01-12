function richLucyDeconvolveFull(MD, deconPSF, apoPSF, maxOTF, imageMultiply, p, photoDir, imageSaveDir, runBlind)

% richLucyDeconvolveFull - performs Richardson-Lucy deconvolution and saves the deconvolved image
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


disp(['  Deconvolving images: ' num2str(MD.nFrames_) ' time points'])  

% find the image size
imageSize = [MD.imSize_(1,1), MD.imSize_(1,2), MD.zSize_(1,1)]; 

% make an apodization filter if wanted
if p.apodizeRL == 1 && p.apoHeight ~= 0 && ~isempty(apoPSF)
    
    % calculate the OTF
    [OTF, imageSize] = calculateSmallOTF(apoPSF, imageSize); clear apoPSF;
    
    % make apodization filter
    apodizeFilter = makeApodizationFilter(OTF, maxOTF, p.apoHeight); clear OTF;
else
    apodizeFilter = [];
    clear apoPSF;
end

% find the PSF size
psfSize = [min(p.PSFsizeRL(1), imageSize(1)), min(p.PSFsizeRL(2), imageSize(2)), min(p.PSFsizeRL(3), imageSize(3))];

% shrink the PSF
deconPSF = deconPSF./sum(deconPSF(:));
originPSF = ceil((size(deconPSF)+ones(1,3))/2); % (for even sizes the origin occurs above the center, i.e. the origin of an image with size 4x4 occurs at (3,3) )
deconPSF = deconPSF((originPSF(1)-ceil((psfSize(1)-1)/2)):(originPSF(1)+floor((psfSize(1)-1)/2)), ...
    (originPSF(2)-ceil((psfSize(2)-1)/2)):(originPSF(2)+floor((psfSize(2)-1)/2)), ...
    (originPSF(3)-ceil((psfSize(3)-1)/2)):(originPSF(3)+floor((psfSize(3)-1)/2)));

% iterate through the images
for c = p.chanList
    parfor t = 1:MD.nFrames_  % can be a parfor loop
    
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
        if min(imageSize==size(image3D)) == 0
            originImage = ceil((imageSize+ones(1,3))/2); % (for even sizes the origin occurs above the center, i.e. the origin of an image with size 4x4 occurs at (3,3) )
            image3D = image3D((originImage(1)-ceil((imageSize(1)-1)/2)):(originImage(1)+floor((imageSize(1)-1)/2)), ...
                (originImage(2)-ceil((imageSize(2)-1)/2)):(originImage(2)+floor((imageSize(2)-1)/2)), ...
                (originImage(3)-ceil((imageSize(3)-1)/2)):(originImage(3)+floor((imageSize(3)-1)/2)));
        end
        
        % deconvolve the image
        if runBlind == 0
            image3D = deconvlucy(image3D, deconPSF, p.richLucyIter);
        else
            [image3D, ~] = deconvblind(image3D, deconPSF, p.richLucyIter);
        end
        
        % save the non-apodized image if wanted 
        if p.saveNotApodized == 1 && p.apodizeRL == 1
            image3DnotApodized = image3D./max(image3D(:));
            image3DnotApodized = imageMultiply*image3DnotApodized;
            image3DnotApodized = uint16((2^16-1)*image3DnotApodized);
            imageName = ['deconNotApodized_' num2str(c) '_' num2str(t) '.tif'];
            imagePath = fullfile(imageSaveDir, imageName);
            save3DImage(image3DnotApodized, imagePath);
        end
        
        % apodize the image if wanted
        if p.apodizeRL == 1 && p.apoHeight ~= 0
            
            % Fourier transform the image
            image3D = fftshift(fftn(image3D));
            
            % perform apodization
            image3D = image3D.*apodizeFilter;
            
            % inverse Fourier transform back to the image domain
            image3D = ifftn(ifftshift(image3D));
            
            % clean up the image
            image3D = abs(image3D);
            image3D = image3D.*(image3D > 0);
        end
        
        % this is a hack
        image3D = image3D./max(image3D(:));
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
        
    end
end
