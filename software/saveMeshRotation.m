function saveMeshRotation(light_handle, rotSavePath, varargin)
% saveMeshRotation - rotate and save the current figure (could be used after plotMeshFigure)
%
% Copyright (C) 2025, Danuser Lab - UTSouthwestern 
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
ip = inputParser;
ip.KeepUnmatched = true;
addRequired(ip, 'light_handle', @(x) numel(x) == 3 && isgraphics(x{1}));
addRequired(ip, 'rotSavePath', @ischar);
% addParameter(ip, 'figHandle', [], @isgraphics);
addParameter(ip, 'movieAVISavePath', '', @ischar);
addParameter(ip, 'setView', [0 90], @isnumeric);
ip.parse(light_handle, rotSavePath, varargin{:});
p = ip.Results;

figHandle = ancestor(light_handle{1}, 'figure','toplevel');

% rotate the figure
% set the view
view(p.setView(1), p.setView(2));
for v = 1:360
    camorbit(1,0,'camera')
    light_handle{1} = camlight(light_handle{1}, 0, 0); 
    light_handle{2} = camlight(light_handle{2}, 120, -60); 
    light_handle{3} = camlight(light_handle{3}, 240, 60);
    %light_handle = camlight(light_handle,'headlight'); 
    lighting phong     
    drawnow
    toName = sprintf('rotate%03d',v);
    saveas(figHandle, fullfile(rotSavePath,toName), 'tiffn');
    if ~isempty(p.movieAVISavePath)
        movieFrames(v) = getframe(figHandle);
    end    
end

if ~isempty(p.movieAVISavePath)
    v = VideoWriter([p.movieAVISavePath filesep  'MeshMovie_Rotation.avi']);
    v.FrameRate = 30;
    open(v);
    writeVideo(v, movieFrames);
    close(v);    
end
 