function edgeList = findEdgesFaceGraph(surface)

% findEdgesFaceGraph - Construct an edge list for the dual graph of the mesh with the faces as nodes
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


% find the faces at each vertex
vertices2faces = makeVertices2Faces(surface);

% find the neighbors of each face
edgeList = zeros(length(surface.faces), 3); % (check that the face indexing does not begin at 0)
for f = 1:size(surface.faces,1)
    
    % the neighboring faces for each of the three vertices that form face f
    v1Faces = vertices2faces{surface.faces(f,1)};
    v2Faces = vertices2faces{surface.faces(f,2)};
    v3Faces = vertices2faces{surface.faces(f,3)};
    
    % each neighboring face will share two vertices in common with face f
    if ~isempty(fastSetDiff(v1Faces, f))
        face1 = fastIntersect(fastSetDiff(v1Faces, f), v2Faces);
        face2 = fastIntersect(fastSetDiff(v1Faces, f), v3Faces);
    else
        face1 = f;
        face2 = f;
    end
    if ~isempty(fastSetDiff(v2Faces, f))
        face3 = fastIntersect(fastSetDiff(v2Faces, f), v3Faces);
    else
        face3 = f;
    end
    
    % if two vertices only have one neighbor, make the face a neighbor of itself
    if isempty(face1), face1 = f; end
    if isempty(face2), face2 = f; end
    if isempty(face3), face3 = f; end
    
    % don't connect across edges that share an irregular number of faces
    % (it would be best if faces were instead connected well)
    if numel(face1) ~=1 || numel(face2) ~=1 || numel(face3) ~=1
        % plotFacesOfVertices(surface, unique([surface.faces(f,1), surface.faces(f,2), surface.faces(f,3)]));
        [face1, face2, face3] = breakFaceGraph(surface,f,face1,face2,face3); % this does not cover all edge cases!
    end
    
    % if the above fails just randomly pick a local face to connect
    face1 = face1(face1>0); face2 = face2(face2>0); face3 = face3(face3>0);
    face1 = face1(1); face2 = face2(1); face3 = face3(1);
    
    % append the faces to the edge list
    edgeList(f,:) = [face1, face2, face3];
    
end
