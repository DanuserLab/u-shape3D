function [neighbors, meanCurvatureSmoothed, meanCurvatureUnsmoothed, gaussCurvatureUnsmoothed, faceNorms] = measureCurvature(mesh, medianFilterRadius, smoothOnMeshIterations)

% measureCurvature - measures and smooths curvature on the mesh surface
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

% calculate the surface normals
[faceNorms,surfaceNorms] = surfaceNormalsFast(mesh);

% calculate the curvature
[gaussCurvatureUnsmoothed, meanCurvatureUnsmoothed] = surfaceCurvatureFast(mesh,surfaceNorms);

% construct a graph of the faces
try % this section is buggy because of irregularities in the mesh
    neighbors = findEdgesFaceGraph(mesh); % construct an edge list for the dual graph where the faces are nodes
catch
    disp('         Warning: The graph could not be constructed!')
    neighbors = [];
    return
end
    
% median filter the curvature in real space
medianFilteredCurvature = medianFilterKD(mesh, meanCurvatureUnsmoothed, medianFilterRadius);

% check for lingering infinities and replace them
if max(medianFilteredCurvature) > 1000  
    maxFiniteMeanCurvature = max(medianFilteredCurvature.*isfinite(medianFilteredCurvature));
    medianFilteredCurvature(medianFilteredCurvature > 1000) = maxFiniteMeanCurvature;    
end

if min(medianFilteredCurvature) < -1000
    minFinite = min(medianFilteredCurvature.*isfinite(medianFilteredCurvature));
    medianFilteredCurvature(medianFilteredCurvature < -1000) = minFinite; 
end

% replace any NaN's
medianFilteredCurvature(~isfinite(medianFilteredCurvature)) = 0;

% diffuse curvature on the mesh geometry
meanCurvatureSmoothed = smoothDataOnMesh(mesh, neighbors, medianFilteredCurvature, smoothOnMeshIterations);
