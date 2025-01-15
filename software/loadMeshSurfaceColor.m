function meshColor = loadMeshSurfaceColor(MD, surfaceMode, chan, frame, colorKey, surfaceSegmentInterIter)

% loadMeshSurfaceColor - determine the color of a mesh for rendering given a plotting mode
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

switch surfaceMode
    case 'blank'
        meshColor = 1; % make the faces monochromatic
        
    case 'curvature'        
        meshColor = loadCurvatureSurfaceColor(MD, chan, frame);
        
    case 'curvatureWatersheds'  % need fix?
        meshColor = loadCurvatureWatershedsSurfaceColor(MD, chan, frame, colorKey);  
        
    case 'curvatureSpillDepth' % need fix?
        meshColor = loadCurvatureSpillDepthSurfaceColor(MD, chan, frame, colorKey);   
        
    case 'surfaceSegment'
        meshColor = loadCurvatureSegmentSurfaceColor(MD, chan, frame, colorKey);   
        
    case 'surfaceSegmentPreLocal' % need fix?
        meshColor = loadSegmentSurfacePreLocalColor(MD, chan, frame, colorKey);  
        
    case 'surfaceSegmentPatchMerge'
        meshColor = loadSegmentSurfacePatchMergeColor(MD, chan, frame, colorKey); 
        
    case 'surfaceSegmentInterTriangle' % need fix?
        meshColor = loadSegmentSurfaceInterTriangleColor(MD, chan, frame, colorKey, surfaceSegmentInterIter);     
        
    case 'surfaceSegmentInterLOS' % need fix?
        meshColor = loadSegmentSurfaceInterLOSColor(MD, chan, frame, colorKey, surfaceSegmentInterIter);     

    case 'protrusions'
        meshColor = loadBlebSurfaceColor(MD, chan, frame, colorKey);
        
    case 'protrusionsType' % need fix?
        meshColor = loadProtrusionsTypeSurfaceColor(MD, chan, frame);    

    case 'SVMscore'
        meshColor = loadSVMscoreSurfaceColor(MD, chan, frame);
        
    case 'SVMscoreThree'
        meshColor = loadSVMscoreThreeSurfaceColor(MD, chan, frame);
        
    case 'clickedOn' % need fix?
        meshColor = loadClickedOnSurfaceColor(MD, chan, frame);    
        
    case 'blebsShrunk' % need fix ?
        meshColor = loadBlebShrunkSurfaceColor(MD, chan, frame, colorKey);
        
%     case 'blebsTracked' % remove not available in distributed
%         meshColor = loadBlebTrackedSurfaceColor(MD, chan, frame, colorKey);
    
%     case 'blebsTrackedOverlap' % remove not available in distributed
%     package
%         meshColor = loadBlebTrackedOverlapSurfaceColor(MD, chan, frame, colorKey);
        
    case 'motion'
        meshColor = loadMotionSurfaceColor(MD, chan, frame);
        
    case 'motionForwards'
        meshColor = loadMotionForwardsSurfaceColor(MD, chan, frame);
        
    case 'intensity'
        meshColor = loadIntensityDepthNormalSurfaceColor(MD, chan, frame);
   
    case 'intensityVertex'
        meshColor = loadIntensityVertexSurfaceColor(MD, chan, frame);
    
    otherwise
        meshColor = 1; % make the faces monochromatic

end