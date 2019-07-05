function colors = makeColormap(type, numColors)

% makeColormap - Make pretty colormaps
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

% Some colormaps are adapted from colorBrewer, while others are custom 
% colormaps.  The colormaps listed as from ColorBrewer are interpolated 
% versions of the colormaps found at <http://colorbrewer2.org/>.
%
% Inputs:
%  type - the specific colormap (See COLORMAPS below)
%  numColors - the number of desired colors in the colormap
%
% Outputs:
%  colors - an RGB colormap
%
% COLORMAPS
%   Sequential colormaps
%     seq_ygb - yellow/green/blue (YlGnBu from ColorBrewer)
%     seq_yor - yellow/orange/red (YlOrRd from ColorBrewer)
%     seq_wor - white/orange/red (OrRd from ColorBrewer)
%     seq_blue - blue (Blues colormap from ColorBrewer)
%     seq_purple - purple (Purples colormap from ColorBrewer)
%     seq_red_custom - red
%
%   Diverging colormaps (0 should be in the middle of the colormap)
%     div_ryb - red/yellow/blue (RdYlBu from ColorBrewer)
%     div_rwb - red/white/blue (RdBu from ColorBrewer)
%     div_pwg - purple/white/green (PRGn from ColorBrewer)
%     div_brwg - brown/white/blue-green (BrBG from Colorbrewer)
%     div_spectral - red/orange/yellow/green/blue (Spectral from ColorBrewer)
%     div_bwr_custom - red/white/blue (designed for the motion measure)
%     div_spectral_custom - spectral (designed for the curvature measure)


% the 'YlGnBu' colormap from ColorBrewer
if strcmp(type, 'seq_ygb')
    
    % define a list of equally spaced colors
    colorList = [255, 255, 217; ...
                 237, 248, 217; ...
                 199, 233, 180; ...
                 127, 205, 187; ...
                 65, 182, 196; ...
                 29, 145, 192; ...
                 34, 94, 168; ...
                 37, 52, 148; ...
                 8, 29, 88];

% the 'YlOrRd' colormap from ColorBrewer
elseif strcmp(type, 'seq_yor')
        
    % define a list of equally spaced colors
    colorList = [255, 255, 204; ...
                 255, 237, 160; ...
                 254, 217, 118; ...
                 254, 178, 76; ...
                 253, 141, 60; ...
                 252, 78, 42; ... 
                 227, 26, 28; ... 
                 189, 0, 38; ...
                 128, 0, 38];

% the 'OrRd' colormap from ColorBrewer
elseif strcmp(type, 'seq_wor')
        
    % define a list of equally spaced colors
    colorList = [255, 255, 255; ...
                 255, 247, 236; ...
                 254, 232, 200; ...
                 253, 212, 158; ...
                 253, 187, 132; ...
                 252, 141, 89; ...
                 239, 101, 72; ...
                 215, 48, 31; ...
                 179, 0, 0; ...
                 127, 0, 0]; 
             
% the 'Blues' colormap from ColorBrewer
elseif strcmp(type, 'seq_blue')
        
    % define a list of equally spaced colors
    colorList = [247, 251, 255; ... 
                 222, 235, 247; ... 
                 198, 219, 239; ... 
                 158, 202, 225; ... 
                 107, 174, 214; ... 
                 66, 146, 198; ... 
                 33, 113, 181; ...
                 8, 81, 156; ... 
                 8, 48, 107];
             
% the 'Purples' colormap from ColorBrewer
elseif strcmp(type, 'seq_purple')
        
    % define a list of equally spaced colors
    colorList = [252, 251, 253; ...
                 239, 237, 245; ...
                 218, 218, 235; ...
                 188, 189, 220; ...
                 158, 154, 200; ...
                 128, 125, 186; ...
                 106, 81, 163; ...
                 84, 39, 143; ...
                 63, 0, 125]; 
                         
% the 'RdYlBu' colormap from ColorBrewer
elseif strcmp(type, 'div_ryb')
        
    % define a list of equally spaced colors
    colorList = [165, 0, 38; ...
                 215, 48, 39; ...
                 244, 109, 67; ...
                 253, 174, 97; ...
                 254, 224, 144; ...
                 255, 255, 191; ...
                 224, 243, 248; ...
                 171, 217, 233; ...
                 116, 173, 209; ...
                 69, 117, 180; ...
                 49, 54, 149]; 
             
% the 'RdBu' colormap from ColorBrewer
elseif strcmp(type, 'div_rwb')
        
    % define a list of equally spaced colors
    colorList = [103, 0, 31; ...
                 178, 24, 43; ...
                 214, 96, 77; ...
                 244, 165, 130; ...
                 253, 219, 199; ...
                 247, 247, 247; ...
                 209, 229, 240; ...
                 146, 197, 222; ...
                 67, 147, 195; ...
                 33, 102, 172; ...
                 5, 48, 97]; 
             
% the 'BrBG' colormap from ColorBrewer
elseif strcmp(type, 'div_brwg')
        
    % define a list of equally spaced colors
    colorList = [84, 48, 5; ...
                 140, 81, 10; ...
                 191, 129, 45; ...
                 223, 194, 125; ...
                 246, 232, 195; ...
                 245, 245, 245; ...
                 199, 234, 229; ...
                 128, 205, 193; ...
                 53, 151, 143; ...
                 1, 102, 94; ...
                 0, 60, 48];              
             
% the 'PRGn' colormap from ColorBrewer
elseif strcmp(type, 'div_pwg')
        
    % define a list of equally spaced colors
    colorList = [64, 0, 75; ...
                 118, 42, 131; ...
                 153, 112, 171; ...
                 194, 165, 207; ...
                 231, 212, 232; ...
                 247, 247, 247; ...
                 217, 240, 211; ...
                 166, 219, 160; ...
                 90, 174, 97; ...
                 27, 120, 55; ...
                 0, 68, 27]; 
                        
% the 'Spectral' colormap from ColorBrewer
elseif strcmp(type, 'div_spectral')
        
    % define a list of equally spaced colors
    colorList = [158, 1, 66; ...
                 213, 62, 79; ...
                 244, 109, 67; ...
                 253, 174, 97; ...
                 254, 224, 139; ...
                 255, 255, 191; ...
                 230, 245, 152; ...
                 171, 221, 164; ...
                 102, 194, 165; ...
                 50, 136, 189; ...
                 94, 79, 162]; 

% a custom ygb colormap           
elseif strcmp(type, 'seq_ygb_custom')  
    
    listSize = 25; % must be odd
    startHue = 1/6; % 1/6 is yellow
    endHue = 2/3; % 2/3 is blue
    minValue = 60; % sets the darkness of the end of the colormap
    minSaturation = 0.1;
        
    % define a list of equally spaced colors
    hue = fliplr(startHue:(endHue-startHue)/(listSize-1):endHue);
    saturation = fliplr(minSaturation:(1-minSaturation)/(listSize-1):1);
    value = minValue:(255-minValue)/(listSize-1):255;
    value = value./255; 
    colorList = hsv2rgb(flipud([hue', saturation', value']));
    
% a custom purple colormap           
elseif strcmp(type, 'seq_rp_custom')  
    
    listSize = 25; % must be odd
    startHue = 8/12; % 0 is red
    endHue = 11/12; % 1/6 is yellow
    minValue = 40; % sets the darkness of the end of the colormap
    minSaturation = 0;
        
    % define a list of equally spaced colors
    hue = startHue:(endHue-startHue)/(listSize-1):endHue;
    saturation = fliplr(minSaturation:(1-minSaturation)/(listSize-1):1);
    value = minValue:(255-minValue)/(listSize-1):255;
    value = value./255; 
    colorList = hsv2rgb(flipud([hue', saturation', value']));
    
% a custom blue colormap           
elseif strcmp(type, 'seq_purple_custom')  
    
    listSize = 25; % must be odd
    startHue = 4/6; % 0 is red
    endHue = 5/6; % 1/6 is yellow
    minValue = 30; % sets the darkness of the end of the colormap
    minSaturation = 0;
        
    % define a list of equally spaced colors
    hue = startHue:(endHue-startHue)/(listSize-1):endHue;
    saturation = fliplr(minSaturation:(1-minSaturation)/(listSize-1):1);
    value = minValue:(255-minValue)/(listSize-1):255;
    value = value./255; 
    colorList = hsv2rgb(flipud([hue', saturation', value']));
    
elseif strcmp(type, 'seq_red_custom')  
    
    listSize = 25; % must be odd
    monoHue = 0; % % 0 is red
    minValue = 160; % sets the darkness of the end of the colormap
    minSaturation = 0.1;
        
    % define a list of equally spaced colors
    hue = monoHue*ones(listSize,1);
    saturation = fliplr(minSaturation:(1-minSaturation)/(listSize-1):1);
    value = minValue:(255-minValue)/(listSize-1):255;
    value = value./255; 
    colorList = hsv2rgb(flipud([hue, (saturation').^2, value']));
             
% a custom red/white/blue colormap
elseif strcmp(type, 'div_bwr_custom')
    
    listSize = 25; % must be odd
    listHalfSize = (listSize-1)/2;
    upperHue = 0.62; % 0.6 is blue
    lowerHue = 0.00; % 0 is red
    minValue = 60; %110 sets the darkness of the ends of the colormap
    saturationGamma = 0.7;
        
    % define a list of equally spaced colors
    hue = [upperHue*ones(1,listHalfSize), 0, lowerHue*ones(1,listHalfSize)]';
    saturation = [fliplr(1/listHalfSize:1/listHalfSize:1), 0, 1/listHalfSize:1/listHalfSize:1]';
    value = [minValue:(255-minValue)/(listHalfSize):255-(255-minValue)/(listHalfSize), 255, fliplr(minValue:(255-minValue)/(listHalfSize):255-(255-minValue)/(listHalfSize))]';
    value = value./255;  
    colorList = hsv2rgb([hue, saturation.^(saturationGamma), value]);
    
% a custom spectral colormap
elseif strcmp(type, 'div_spectral_custom')
    
    listSize = 25; % must be odd
    listHalfSize = (listSize-1)/2;
    
    lowerHue = 0; % 0 is red
    upperHue = 0.66; % 0.6 is blue
    minSaturation = 0.15;  %sets the saturation in the middle of the colormap
    minValue = 140; % sets the darkness of the ends of the colormap, 120
    maxValue = 255; % sets the darkness in the middle of the colormap
    hueGamma = 3.5;
    saturationGamma = 0.4;
    
    % define a list of equally spaced colors  
    huesFirst = lowerHue:(upperHue-lowerHue)/(2*listHalfSize):(upperHue-lowerHue)/2;
    huesFirstAdjusted = huesFirst.^hueGamma;
    huesFirstAdjusted = huesFirstAdjusted.*(huesFirst(end)/max(huesFirstAdjusted));
    huesSecondAdjusted = fliplr(upperHue - huesFirstAdjusted);
    hue = flipud([huesFirstAdjusted(1:end-1), huesSecondAdjusted]');
    saturation = [fliplr(minSaturation+(1-minSaturation)/listHalfSize:(1-minSaturation)/listHalfSize:1), minSaturation, minSaturation+(1-minSaturation)/listHalfSize:(1-minSaturation)/listHalfSize:1]';
    value = [minValue:(maxValue-minValue)/(listHalfSize):maxValue-(maxValue-minValue)/(listHalfSize), maxValue, fliplr(minValue:(maxValue-minValue)/(listHalfSize):maxValue-(maxValue-minValue)/(listHalfSize))]';
    value = value./255;
    colorList = hsv2rgb([hue, saturation.^(saturationGamma), value]);
    
end 
      
% interpolate the colors
offset = floor(numColors/(length(colorList)*2-1));
colors = imresize(colorList, [numColors+2*offset, 3], 'bilinear');
colors = colors(offset+1:end-offset, :);

% force the minimum color to be greater than or equal to 0       
if min(colors(:)) < 0
   colors = colors - min(colors(:));
end

% force the maximum color to be less than or equal to 1       
if max(colors(:)) > 1
    colors = colors./max(colors(:));
end
