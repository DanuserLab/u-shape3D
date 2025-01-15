function surfaceSegmentPatchMerge = mergePatchesSVM(surface, surfaceSegment, pairStats, inSVMmodel, svmModel, neighbors, meanCurvature, meanCurvatureUnsmoothed, gaussCurvatureUnsmoothed, pixelSize)

% surfaceSegmentPatchMerge - merge patches according to an SVM model
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

% set parameters
SVMcutoff = 0;
flipSVMscore = 0;
% define an initial list of adjacent pairs to consider for merging
edgesToCheck = pairStats.patchPairs;

% for the initial list of pairs, find the SVM score
measuresInitial = makeMeasuresMatrixForPatchMerging(pairStats, inSVMmodel, pixelSize);
[svmLabel, svmScore] = predict(svmModel, measuresInitial); 
svmScore = svmScore(:,1);

% if needed, modify the svm score such that a high value indicates that patches should be merged
if sum(svmScore(svmLabel == 1)) < 0
    svmScore = -1*svmScore;
    flipSVMscore = 1;
end

% append the svmScore to the pair list and sort by svm score
edgesToCheck = [edgesToCheck, svmScore];
edgesToCheck = sortrows(edgesToCheck, -3);

% construct a graph of the patch adjacency
[patchLabels, patchGraph] = makeGraphFromLabel(neighbors, surfaceSegment, 1); 

% find the boundary faces
onBoundary = findBoundaryFaces(surfaceSegment, neighbors, 'single');

% measure the area of each face
areas = measureAllFaceAreas(surface); 

% calculate the principal curvatures
kappa1 = real(-1*meanCurvatureUnsmoothed + sqrt(meanCurvatureUnsmoothed.^2-gaussCurvatureUnsmoothed));
kappa2 = real(-1*meanCurvatureUnsmoothed - sqrt(meanCurvatureUnsmoothed.^2-gaussCurvatureUnsmoothed));

% calculate curvature statistics
curvatureStatsGlobal.meanCurvature = mean(meanCurvature);
curvatureStatsGlobal.stdCurvature = std(meanCurvature);
curvatureStatsGlobal.curvature20 = prctile(meanCurvature,20);
curvatureStatsGlobal.curvature80 = prctile(meanCurvature,80);
curvatureStatsGlobal.gaussCurvature20 = prctile(gaussCurvatureUnsmoothed,20);
curvatureStatsGlobal.gaussCurvature80 = prctile(gaussCurvatureUnsmoothed,80);
curvatureStatsGlobal.curvature10 = prctile(meanCurvature,10);
curvatureStatsGlobal.curvature90 = prctile(meanCurvature,90);

% merge regions until no adjacent regions exceed the SVM score
labelIndex = 1:length(patchLabels);
while ~isempty(edgesToCheck) && edgesToCheck(1,3) >= SVMcutoff
    
    disp(['svm ', num2str(length(unique(surfaceSegment)))])
    
    % find the labels of the patches
    mergeLabel = min(edgesToCheck(1,1:2));
    if mergeLabel < 0, mergeLabel = max(edgesToCheck(1,1:2)); end 
    mergeDestroy = setdiff(edgesToCheck(1,1:2), mergeLabel);
    
    % find the indices of the labels in patchGraphs
    mergeLabelIndex = labelIndex(patchLabels==mergeLabel);
    mergeDestroyIndex = labelIndex(patchLabels==mergeDestroy);
    
    % make a list of patches in which the two regions are merged 
    surfaceSegmentCombined = surfaceSegment;    
    if mergeLabel==edgesToCheck(1,1)
        surfaceSegmentCombined(surfaceSegment==edgesToCheck(1,2)) = mergeLabel;
    else
        surfaceSegmentCombined(surfaceSegment==edgesToCheck(1,1)) = mergeLabel;
    end
    
    % update the list of patches indexed by face
    surfaceSegment = surfaceSegmentCombined;
    
    % update watershedGraph, which lists the neighbors of each patch
    neighborsOfDestroyed = patchGraph{mergeDestroyIndex}; % find the neighbors of the desroyed label
    neighborsOfDestroyed = setdiff(neighborsOfDestroyed, mergeLabel);
    patchGraph{mergeLabelIndex} = setdiff([patchGraph{mergeLabelIndex}, neighborsOfDestroyed], [mergeLabel, mergeDestroy]); % update mergeLabel
    patchGraph{mergeDestroyIndex} = []; % update the destroyed label
    for n = 1:length(neighborsOfDestroyed) % replace the destoyed label with the merged label in each of the destroyed neighbors lists of neighbors
        neighborIndex = labelIndex'.*(patchLabels==neighborsOfDestroyed(n));
        neighborIndex = neighborIndex(neighborIndex~=0);
        patchGraph{neighborIndex} = setdiff([patchGraph{neighborIndex}, mergeLabel], mergeDestroy);
    end
    
    % remove all instances of both patches in the list of edges to check
    toRemove = logical( (edgesToCheck(:,1)==mergeLabel) + (edgesToCheck(:,2)==mergeLabel) + ...
        (edgesToCheck(:,1)==mergeDestroy) + (edgesToCheck(:,2)==mergeDestroy) );
    edgesToCheckFrom = edgesToCheck(:,1); edgesToCheckTo = edgesToCheck(:,2); score = edgesToCheck(:,3);
    edgesToCheckFrom(toRemove) = []; edgesToCheckTo(toRemove) = []; score(toRemove) = []; 
    edgesToCheck = [edgesToCheckFrom, edgesToCheckTo, score];
    
    % remove the pair that was checked from the list of regions to check
    if ~isempty(edgesToCheck)
        edgesToCheck(1,:) = [];
    else
%         disp('edges to check done.');
        edgesToCheck = [];
    end
       

    % find a list of neighbors of the combined region to measure the svm score of
    nLabels = patchGraph{mergeLabelIndex};
    edgesToAdd = [mergeLabel.*ones(length(nLabels),1), nLabels', NaN(length(nLabels),1)];
    
    % calculate the svm score between all pairs of new adjacent patches found
    pairStatsNew = [];
    for p = 1:size(edgesToAdd,1) 
        statsOnePair = calculatePairStatsOnePair(edgesToAdd(p,1), edgesToAdd(p,2), surface, surfaceSegment, neighbors, onBoundary, areas, meanCurvature, gaussCurvatureUnsmoothed, kappa1, kappa2, curvatureStatsGlobal);
        pairStatsNew = unpackStatisticsPairStats(statsOnePair, pairStatsNew, p);
        
    end
    if ~isempty(edgesToAdd)
        measuresNew = makeMeasuresMatrixForPatchMerging(pairStatsNew, inSVMmodel, pixelSize);
        [~, newSVMscore] = predict(svmModel, measuresNew);
        if flipSVMscore == 1, newSVMscore = -1*newSVMscore; end
        edgesToAdd(:,3) = newSVMscore(:,1);
        
        % update the list of edges to check
        edgesToCheck = [edgesToCheck; edgesToAdd];
        
    end
    
    if ~isempty(edgesToCheck)
        if size(edgesToCheck,1) > 1
            % sort the list of edges to check
            edgesToCheck = sortrows(edgesToCheck, -3);
        end
    else
        disp('edges to check done.');
        edgesToCheck = [];
    end

1;
end

surfaceSegmentPatchMerge = surfaceSegment;