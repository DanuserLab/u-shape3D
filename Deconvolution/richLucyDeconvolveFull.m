function richLucyDeconvolveFull(MD, PSF, imageMultiply, p, photoDir, imageSaveDir)

% weinerDeconvolveFull - performs Richardson-Lucy deconvolution and saves the deconvolved image
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
imageMultiply = 0.99;

% Richardson-Lucy deconvolve the images
disp(['  Deconvolving images: ' num2str(MD.nFrames_) ' time points'])  

% find the image size
imageSize = [min(512, MD.imSize_(1,1)), min(512, MD.imSize_(1,2)), min(512, MD.zSize_(1,1))]; % you may not want the 512!!!!!

% shrink the PSF to the image size
PSF = PSF./sum(PSF(:));
originPSF = ceil((size(PSF)+ones(1,3))/2); % (for even sizes the origin occurs above the center, i.e. the origin of an image with size 4x4 occurs at (3,3) )
PSF = PSF((originPSF(1)-ceil((imageSize(1)-1)/2)):(originPSF(1)+floor((imageSize(1)-1)/2)), ...
    (originPSF(2)-ceil((imageSize(2)-1)/2)):(originPSF(2)+floor((imageSize(2)-1)/2)), ...
    (originPSF(3)-ceil((imageSize(3)-1)/2)):(originPSF(3)+floor((imageSize(3)-1)/2)));

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
        
        % deconvolve the image
        image3D = deconvlucy(image3D, PSF, p.richLucyIter);
        
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