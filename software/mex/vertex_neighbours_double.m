function Ne=vertex_neighbours_double(Fa,Fb,Fc,Vx,Vy,Vz)

F=[Fa Fb Fc];
V=[Vx Vy Vz];

% Neighbourh cell array 
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
Ne=cell(1,size(V,1));

% Loop through all faces
for i=1:length(F)
    % Add the neighbors of each vertice of a face
    % to his neighbors list.
    Ne{F(i,1)}=[Ne{F(i,1)} [F(i,2) F(i,3)]];
    Ne{F(i,2)}=[Ne{F(i,2)} [F(i,3) F(i,1)]];
    Ne{F(i,3)}=[Ne{F(i,3)} [F(i,1) F(i,2)]];
end

% Loop through all neighbor arrays and sort them (Rotation same as faces)
for i=1:size(V,1)
 
    Pneighf=Ne{i};
    if(isempty(Pneighf))
        Pneig=[];
    else
        start=1;
        for index1=1:2:length(Pneighf)
            found=false;
            for index2=2:2:length(Pneighf),
                if(Pneighf(index1)==Pneighf(index2))
                    found=true; break
                end
            end
            if(~found)
                start=index1; break
            end
        end
        Pneig=[];
        Pneig(1)=Pneighf(start);
        Pneig(2)=Pneighf(start+1);
        
        % Add the neighbours with respect to original rotation
        for j=2+double(found):(length(Pneighf)/2)
            found = false;
            for index=1:2:length(Pneighf),
                if(Pneighf(index)==Pneig(end))
                    if(sum(Pneig==Pneighf(index+1))==0)
                        found =true;
                        Pneig=[Pneig Pneighf(index+1)];
                    end
                end
            end
            if(~found) % This only happens with weird edge vertices
                for index=1:2:length(Pneighf),
                    if(sum(Pneig==Pneighf(index))==0)
                        Pneig=[Pneig Pneighf(index)];
                        if(sum(Pneig==Pneighf(index+1))==0)
                            Pneig=[Pneig Pneighf(index+1)];
                        end
                    end
                end
            end
        end
        % Add forgotten neigbours
        if(length(Pneig)<length(Pneighf))
            for j=1:length(Pneighf)
                if(sum(Pneig==Pneighf(j))==0)
                    Pneig=[Pneig Pneighf(j)];
                end
            end
        end
    end
    Ne{i}=Pneig;
end



