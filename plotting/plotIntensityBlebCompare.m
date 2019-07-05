function plotIntensityBlebCompare(p)

% plotIntensityBlebCompare - plots some bleb paper-specific plots using data calculated by the IntensityBlebCompare Process
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


% check inputs
if ~isfield(p, 'analyzeOtherChannel'), p.analyzeOtherChannel = 0; end
assert(p.analyzeOtherChannel == 0 | p.analyzeOtherChannel == 1, 'p.analyzeOtherChannel must be either left unset or set to 0 or 1');

if ~isfield(p, 'analyzeDiffusion'), p.analyzeDiffusion = 0; end
assert(p.analyzeDiffusion == 0 | p.analyzeDiffusion == 1, 'p.analyzeDiffusion must be either left unset or set to 0 or 1');

if ~isfield(p, 'analyzeDistance'), p.analyzeDistance = 0; end
assert(p.analyzeDistance == 0 | p.analyzeDistance == 1, 'p.analyzeDistance must be either left unset or set to 0 or 1');

if ~isfield(p, 'analyzeForwardsMotion'), p.analyzeForwardsMotion = 0; end
assert(p.analyzeForwardsMotion == 0 | p.analyzeForwardsMotion == 1, 'p.analyzeForwardsMotion must be either left unset or set to 0 or 1');

if ~isfield(p, 'analyzeVonMises'), p.analyzeVonMises = 0; end
assert(p.analyzeVonMises == 0 | p.analyzeVonMises == 1, 'p.analyzeVonMises must be either left unset or set to 0 or 1');

% make a directory to save data in
if ~isfolder(p.savePath), mkdirRobust(p.savePath); end

% initialize variables
meanIntensityBlebCells = []; meanIntensityNotBlebCells = [];
maxIntensityBlebCells = []; maxIntensityNotBlebCells = [];
isProtrusionPatches = []; isCertainProtrusionPatches = [];
meanIntensityPatches = []; maxIntensityPatches = [];
meanMotionPatches = []; 
volumePatches = [];
isProtrusionFaces = []; isCertainProtrusionFaces = [];
intensityFaces = []; motionFaces = []; curvatureFaces = [];
if p.analyzeOtherChannel == 1
    meanIntensityOtherPatches = []; maxIntensityOtherPatches = [];
    intensityOtherFaces = [];
end
if p.analyzeDiffusion == 1
    diffusedProtrusionsFaces = [];
    diffusedSVMFaces = [];
end
if p.analyzeDistance == 1
    distanceFaces = [];
end
if p.analyzeForwardsMotion == 1
    meanForwardsMotionPatches = [];
    forwardsMotionFaces = [];
end
if p.analyzeVonMises == 1
    vonMisesBlebs = [];
    vonMisesBlebsRand = [];
    vonMisesIntensity = [];
    vonMisesNegCurvature = [];
    vonMisesIntensityMin = [];
end
cellIndexPatches = []; cellIndexFaces = [];

% iterate through the list of cells
for s = 1:length(p.cellsList)
    
    % display progress
    %disp(['Cell ' num2str(s) ' of ' num2str(length(p.cellsList))]);
    
    % load the bleb and intensity statistics
    analysisPath = fullfile(p.mainDirectory, p.cellsList{s}, 'Morphology', 'Analysis', 'IntensityBlebCompare');
    statsStruct = load(fullfile(analysisPath, 'stats.mat'));
    comparePatches = statsStruct.comparePatches;
    compareFaces = statsStruct.compareFaces;
    vonMises = statsStruct.vonMises;
    convert = statsStruct.convert; 
    
    % append and subset data in the comparePatches variable
    isProtrusionPatches = [isProtrusionPatches, comparePatches.isProtrusion];
    isCertainProtrusionPatches = [isCertainProtrusionPatches, comparePatches.isCertainProtrusion];
    meanIntensityPatches = [meanIntensityPatches, comparePatches.meanIntensity];
    maxIntensityPatches = [maxIntensityPatches, comparePatches.maxIntensity];
    meanMotionPatches = [meanMotionPatches, convert.motion*comparePatches.meanMotion];
    volumePatches = [volumePatches, convert.volume*comparePatches.volume];
    if p.analyzeOtherChannel == 1
        meanIntensityOtherPatches = [meanIntensityOtherPatches, comparePatches.meanIntensityOther];
        maxIntensityOtherPatches = [maxIntensityOtherPatches, comparePatches.maxIntensityOther];
    end
    if p.analyzeForwardsMotion == 1
        meanForwardsMotionPatches = [meanForwardsMotionPatches, convert.motion*comparePatches.meanForwardsMotion];
    end
    
    % append and subset data in the compareFaces variable
    isProtrusionFaces = [isProtrusionFaces, compareFaces.isProtrusion];
    isCertainProtrusionFaces = [isCertainProtrusionFaces, compareFaces.isCertainProtrusion];
    intensityFaces = [intensityFaces, compareFaces.intensityNormal];
    motionFaces = [motionFaces, convert.motion*compareFaces.motion];
    curvatureFaces = [curvatureFaces, convert.curvature*compareFaces.curvature];
    if p.analyzeOtherChannel == 1
        intensityOtherFaces = [intensityOtherFaces, compareFaces.intensityOtherNormal];
    end
    if p.analyzeDiffusion == 1
        diffusedProtrusionsFaces = [diffusedProtrusionsFaces, compareFaces.diffusedProtrusions];
        diffusedSVMFaces = [diffusedSVMFaces, compareFaces.diffusedSVM];
    end
    if p.analyzeForwardsMotion == 1
        forwardsMotionFaces = [forwardsMotionFaces, convert.motion*compareFaces.forwardsMotion];
    end
    if p.analyzeDistance == 1
        distanceFaces = [distanceFaces, convert.edgeLength.*compareFaces.distanceTransformProtrusions];
    end
    
    % append polarization data
    if p.analyzeVonMises == 1
        vonMisesBlebs = [vonMisesBlebs; vonMises.blebs];
        vonMisesBlebsRand = [vonMisesBlebsRand; vonMises.blebsRand];
        vonMisesIntensity = [vonMisesIntensity; vonMises.intensity];
        vonMisesNegCurvature = [vonMisesNegCurvature; vonMises.negCurvature];
        vonMisesIntensityMin = [vonMisesIntensityMin; vonMises.intensityMin];
    end
    
    % keep track of the different cells
    cellIndexPatches = [cellIndexPatches, s.*ones(1,length(comparePatches.isProtrusion))];
    cellIndexFaces = [cellIndexFaces, s.*ones(1,length(compareFaces.isProtrusion))];
    
    % find the mean patch intensity for blebs and non-blebs
    meanIntensityBlebCells = [meanIntensityBlebCells, mean(comparePatches.meanIntensity(comparePatches.isProtrusion == 1))];
    meanIntensityNotBlebCells = [meanIntensityNotBlebCells, mean(comparePatches.meanIntensity(comparePatches.isProtrusion == 0))];
    maxIntensityBlebCells = [maxIntensityBlebCells, mean(comparePatches.maxIntensity(comparePatches.isProtrusion == 1))];
    maxIntensityNotBlebCells = [maxIntensityNotBlebCells, mean(comparePatches.maxIntensity(comparePatches.isProtrusion == 0))];
end

% check to see if the motion plots should be made
if sum(isfinite(motionFaces)) > 0
    makeMotionPlots = 1;
else
    makeMotionPlots = 0;
end

%% Plot histograms of the intensity on blebs and non-blebs (patch)
numBins = 12; 
f = figure;
h = histogram(meanIntensityPatches(isProtrusionPatches==1), numBins, 'Normalization', 'probability');
hold on
histogram(meanIntensityPatches(isProtrusionPatches==0), h.BinEdges, 'Normalization', 'probability');
legend({'bleb', 'nonBleb'}); colormap(jet);
xlabel('Normalized Intensity'); ylabel('Frequency'); 
title('Mean Intensity of Blebs and Non-Blebs (Patches)'); 
saveName = fullfile(p.savePath, 'meanIntensityBlebsHistogramPatches');
saveas(f, saveName, 'epsc'); savefig(f, saveName);

f = figure;
h = histogram(maxIntensityPatches(isProtrusionPatches==1), numBins, 'Normalization', 'probability');
hold on
histogram(maxIntensityPatches(isProtrusionPatches==0), h.BinEdges, 'Normalization', 'probability');
legend({'bleb', 'nonBleb'}); colormap(jet);
xlabel('Normalized Intensity'); ylabel('Frequency');
title('Max Intensity of Blebs and Non-Blebs (Patches)');
saveName = fullfile(p.savePath, 'maxIntensityBlebsHistogramPatches');
saveas(f, saveName, 'epsc'); savefig(f, saveName);

% plot the cell by cell mean patch intensity for blebs and non-blebs and perform statistical tests
[~,pVal,ci,~] = ttest(meanIntensityBlebCells, meanIntensityNotBlebCells,'Tail','right');
disp('Cell to Cell Stats: One-sided t-test on the average mean intensity on blebs and nonBlebs');
disp(['  p value: ' num2str(pVal)]);
disp(['Number of frames: ' num2str(length(meanIntensityBlebCells))]);
disp(['Number of patches: ' num2str(length(meanIntensityPatches))]);
disp(['Number of faces: ' num2str(length(intensityFaces))]);

% fig = figure;
% plot(ones(1,length(meanIntensityBlebCells)), meanIntensityBlebCells, 'Color', [0.5 0.5 0.5], 'LineStyle', 'none', 'Marker', 'o', 'LineWidth', 2, 'MarkerSize', 10);
% hold on
% plot(2*ones(1,length(meanIntensityNotBlebCells)), meanIntensityNotBlebCells, 'Color', [0.5 0.5 0.5], 'LineStyle', 'none', 'Marker', 'o', 'LineWidth', 2, 'MarkerSize', 10);
% errorbar([1,2], [mean(meanIntensityBlebCells), mean(meanIntensityNotBlebCells)], [std(meanIntensityBlebCells)/sqrt(length(meanIntensityBlebCells)), std(meanIntensityNotBlebCells)/sqrt(length(meanIntensityNotBlebCells))], 'LineWidth', 2, 'Color', 'k', 'LineStyle', 'none', 'Marker', '+', 'MarkerSize', 24);
% axis([0 3 -Inf Inf]);
% title('Blebs (left) and nonBlebs (right)')
fig = figure;
plot(ones(1,length(meanIntensityBlebCells)), meanIntensityBlebCells-meanIntensityNotBlebCells, 'Color', [0.5 0.5 0.5], 'LineStyle', 'none', 'Marker', 'o', 'LineWidth', 2, 'MarkerSize', 10);
hold on
errorbar([1], [mean(meanIntensityBlebCells-meanIntensityNotBlebCells)], [std(meanIntensityBlebCells-meanIntensityNotBlebCells)/sqrt(length(meanIntensityNotBlebCells))], 'LineWidth', 2, 'Color', 'k', 'LineStyle', 'none', 'Marker', '+', 'MarkerSize', 24);
ylabel('Intensity Dif')
title('Intensity Difference Between Blebs and Non-blebs (cells)')

%% Plot histograms of the intensity on blebs and non-blebs (faces)
numBins = 48;

% f = figure;
% h = histogram(intensityFaces(isProtrusionFaces==1), numBins);
% hold on
% histogram(intensityFaces(isProtrusionFaces==0), h.BinEdges);
% legend({'bleb', 'nonBleb'}); colormap(jet);
% xlabel('Normalized Intensity'); ylabel('Count'); 
% title('Intensity on Blebs and Non-Blebs, Non-normalized, (Faces)'); 
% saveName = fullfile(p.savePath, 'intensityBlebsNonNormalHistogramFaces');
% saveas(f, saveName, 'epsc'); savefig(f, saveName);

% plot as line plots rather than histograms
f = figure;
binWidth = 0.04; binMax = 2;
edges = 0:binWidth:binMax;
edgeCenters = (edges(1:end-1)+edges(2:end))/2;
protrusionsN = histcounts(intensityFaces(isProtrusionFaces==1), edges);
notProtrusionsN = histcounts(intensityFaces(isProtrusionFaces==0), edges);
plot(edgeCenters, protrusionsN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
hold on
plot(edgeCenters, notProtrusionsN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
legend({'bleb', 'nonBleb'}); colormap(jet);
xlabel('Normalized Intensity'); ylabel('Frequency');
title('Intensity on Blebs and Non-Blebs, Non-normalized (Faces)');
%axis([-5 5 -inf inf])
saveName = fullfile(p.savePath, 'intensityBlebsNonNormalHistogramLinesFaces');
saveas(f, saveName, 'epsc'); savefig(f, saveName);

% f = figure;
% h = histogram(intensityFaces(isProtrusionFaces==1), numBins, 'Normalization', 'probability');
% hold on
% histogram(intensityFaces(isProtrusionFaces==0), h.BinEdges, 'Normalization', 'probability');
% legend({'bleb', 'nonBleb'}); colormap(jet);
% xlabel('Normalized Intensity'); ylabel('Frequency'); 
% title('Intensity on Blebs and Non-Blebs (Faces)'); 
% saveName = fullfile(p.savePath, 'intensityBlebsHistogramFaces');
% saveas(f, saveName, 'epsc'); savefig(f, saveName);

% plot as line plots rather than histograms
f = figure;
binWidth = 0.04; binMax = 2;
edges = 0:binWidth:binMax;
edgeCenters = (edges(1:end-1)+edges(2:end))/2;
protrusionsN = histcounts(intensityFaces(isProtrusionFaces==1), edges, 'Normalization', 'probability');
notProtrusionsN = histcounts(intensityFaces(isProtrusionFaces==0), edges, 'Normalization', 'probability');
plot(edgeCenters, protrusionsN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
hold on
plot(edgeCenters, notProtrusionsN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
legend({'bleb', 'nonBleb'}); colormap(jet);
xlabel('Normalized Intensity'); ylabel('Frequency');
title('Intensity on Blebs and Non-Blebs (Faces)');
%axis([-5 5 -inf inf])
saveName = fullfile(p.savePath, 'intensityBlebsHistogramLinesFaces');
saveas(f, saveName, 'epsc'); savefig(f, saveName);


%% Plot histograms of the motion on blebs and non-blebs (faces)
if makeMotionPlots == 1
    f = figure; 
    binWidth = 0.1; binMax = 5;
    edges = -binMax:binWidth:binMax;
    h = histogram(motionFaces(isProtrusionFaces==1), edges, 'Normalization', 'probability');
    hold on
    g = histogram(motionFaces(isProtrusionFaces==0), h.BinEdges, 'Normalization', 'probability');
    legend({'bleb', 'nonBleb'}); colormap(jet);
    xlabel('Motion (microns/minute)'); ylabel('Frequency'); 
    title('Motion on Blebs and Non-Blebs (Faces)'); 
    axis([-5 5 -inf inf])
    saveName = fullfile(p.savePath, 'motionBlebsHistogramFaces');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
    % plot protrusive minus retractive motion
    f = figure; 
    xCoord = (binWidth/2):binWidth:(binMax-binWidth/2);
    plot(xCoord, h.Values(0.5*(length(edges)-1)+1:end) - fliplr(h.Values(1:0.5*(length(edges)-1))), 'LineWidth', 2)
    hold on
    plot(xCoord, g.Values(0.5*(length(edges)-1)+1:end) - fliplr(g.Values(1:0.5*(length(edges)-1))), 'LineWidth', 2)
    legend({'bleb', 'nonBleb'}); colormap(jet);
    xlabel('Motion (microns/minute)'); ylabel('Frequency Protrusive - Frequency Retractive Motion'); 
    title('Protrusive-Retractive Motion')
    saveName = fullfile(p.savePath, 'protrusiveMinusRetractiveBlebsFaces');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
    % plot as line plots rather than histograms
    f = figure; 
    binWidth = 0.1; binMax = 5;
    edges = -binMax:binWidth:binMax;
    edgeCenters = (edges(1:end-1)+edges(2:end))/2;
    protrusionsN = histcounts(motionFaces(isProtrusionFaces==1), edges, 'Normalization', 'probability');
    notProtrusionsN = histcounts(motionFaces(isProtrusionFaces==0), edges, 'Normalization', 'probability');
    protrusionsN(length(edgeCenters)/2:length(edgeCenters)/2+1) = NaN;
    notProtrusionsN(length(edgeCenters)/2:length(edgeCenters)/2+1) = NaN;
    plot(edgeCenters, protrusionsN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
    hold on
    plot(edgeCenters, notProtrusionsN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
    legend({'bleb', 'nonBleb'}); colormap(jet);
    xlabel('Motion (microns/minute)'); ylabel('Frequency'); 
    title('Motion on Blebs and Non-Blebs (Faces)'); 
    axis([-5 5 -inf inf])
    saveName = fullfile(p.savePath, 'motionBlebsHistogramLinesFaces');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
    % plot as line plots rather than histograms
    f = figure;
    binWidth = 0.25; binMax = 5;
    edges = -binMax:binWidth:binMax;
    edgeCenters = (edges(1:end-1)+edges(2:end))/2;
    protrusionsN = histcounts(motionFaces(isProtrusionFaces==1), edges, 'Normalization', 'probability');
    notProtrusionsN = histcounts(motionFaces(isProtrusionFaces==0), edges, 'Normalization', 'probability');
    plot(edgeCenters, protrusionsN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
    hold on
    plot(edgeCenters, notProtrusionsN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
    legend({'bleb', 'nonBleb'}); colormap(jet);
    xlabel('Motion (microns/minute)'); ylabel('Frequency'); 
    title('Motion on Blebs and Non-Blebs (Faces)'); 
    axis([-5 5 -inf inf])
    saveName = fullfile(p.savePath, 'motionBlebsHistogramLinesFacesLargerBin');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
    % forwards motion
    if p.analyzeForwardsMotion == 1
        f = figure;
        binWidth = 0.05; binMax = 5;
        edges = -binMax:binWidth:binMax;
        h = histogram(forwardsMotionFaces(isProtrusionFaces==1), edges, 'Normalization', 'probability');
        hold on
        g = histogram(forwardsMotionFaces(isProtrusionFaces==0), h.BinEdges, 'Normalization', 'probability');
        legend({'bleb', 'nonBleb'}); colormap(jet);
        xlabel('Forwards Motion (microns/minute)'); ylabel('Frequency'); 
        title('Forwards Motion on Blebs and Non-Blebs (Faces)'); 
        axis([-5 5 -inf inf])
        saveName = fullfile(p.savePath, 'forwardsMotionBlebsHistogramFaces');
        saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
        % plot protrusive minus retractive motion
        f = figure;
        xCoord = (binWidth/2):binWidth:(binMax-binWidth/2);
        plot(xCoord, h.Values(0.5*(length(edges)-1)+1:end) - fliplr(h.Values(1:0.5*(length(edges)-1))), 'LineWidth', 2)
        hold on
        plot(xCoord, g.Values(0.5*(length(edges)-1)+1:end) - fliplr(g.Values(1:0.5*(length(edges)-1))), 'LineWidth', 2)
        legend({'bleb', 'nonBleb'}); colormap(jet);
        xlabel('Forwards Motion (microns/minute)'); ylabel('Frequency Protrusive - Frequency Retractive Motion'); 
        title('Protrusive-Retractive Forwards Motion')
        saveName = fullfile(p.savePath, 'protrusiveMinusRetractiveForwardsBlebsFaces');
        saveas(f, saveName, 'epsc'); savefig(f, saveName);
    end

end


%% Plot histograms of motion for blebs of different intensities (faces and patches)
if makeMotionPlots == 1
    meanIntensity = mean(intensityFaces(logical(isProtrusionFaces)));
    stdIntensity = std(intensityFaces(logical(isProtrusionFaces)));

    f = figure;
    numBins = 100;
    h = histogram(motionFaces(isProtrusionFaces==1 & intensityFaces>meanIntensity), numBins, 'Normalization', 'probability');
    hold on
    histogram(motionFaces(isProtrusionFaces==1 & intensityFaces<=meanIntensity), h.BinEdges, 'Normalization', 'probability');
    legend({'above mean intensity', 'below mean intensity'}); colormap(jet);
    xlabel('Motion (microns/minute)'); ylabel('Frequency'); 
    title('Motion on Blebs of Different Intensities (Faces)'); 
    axis([-5 5 -inf inf])
    saveName = fullfile(p.savePath, 'motionBlebsByIntensityMeanHistogramFaces');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);

%     f = figure;
%     numBins = 100;
%     h = histogram(motionFaces(isProtrusionFaces==1 & intensityFaces>(meanIntensity+stdIntensity)), numBins, 'Normalization', 'probability');
%     hold on
%     histogram(motionFaces(isProtrusionFaces==1 & intensityFaces<=(meanIntensity-stdIntensity)), h.BinEdges, 'Normalization', 'probability');
%     legend({'> 1 std above mean intensity', '< 1 std below mean intensity'}); colormap(jet);
%     xlabel('Motion (microns/minute)'); ylabel('Frequency'); 
%     title('Motion on Blebs of Different Intensities (Faces)'); 
%     axis([-5 5 -inf inf])
%     saveName = fullfile(p.savePath, 'motionBlebsByIntensitySTDHistogramFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
%     
%     f = figure;
%     numBins = 100;
%     h = histogram(motionFaces(isProtrusionFaces==1 & intensityFaces>(meanIntensity+stdIntensity)), numBins, 'Normalization', 'probability');
%     hold on
%     histogram(motionFaces(isProtrusionFaces==1 & intensityFaces>=(meanIntensity-stdIntensity) & intensityFaces<(meanIntensity+stdIntensity)), h.BinEdges, 'Normalization', 'probability');
%     histogram(motionFaces(isProtrusionFaces==1 & intensityFaces<=(meanIntensity-stdIntensity)), h.BinEdges, 'Normalization', 'probability');
%     legend({'x > 1 std above mean intensity', '-1 < x < 1 std below mean intensity', 'x < -1 std below mean intensity'}); colormap(jet);
%     xlabel('Motion (microns/minute)'); ylabel('Frequency'); 
%     title('Motion on Blebs of Different Intensities (Faces)'); 
%     axis([-5 5 -inf inf])
%     saveName = fullfile(p.savePath, 'motionBlebsByIntensityManySTDHistogramFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
%     
%     f = figure;
%     binWidth = 0.1; binMax = 5;
%     edges = -binMax:binWidth:binMax;
%     intensityProtrusionFaces = intensityFaces(isProtrusionFaces==1);
%     intensity10 = prctile(intensityProtrusionFaces,10);
%     intensity90 = prctile(intensityProtrusionFaces,90);
%     h = histogram(motionFaces(isProtrusionFaces==1 & intensityFaces>intensity90), edges, 'Normalization', 'probability');
%     hold on
%     g = histogram(motionFaces(isProtrusionFaces==1 & intensityFaces<=intensity10), edges, 'Normalization', 'probability');
%     legend({'> 90th intensity percentile', '< 10th intensity percentile'}); colormap(jet);
%     xlabel('Motion (microns/minute)'); ylabel('Frequency'); 
%     title('Motion on Blebs of Different Intensities (Faces)'); 
%     axis([-5 5 -inf inf])
%     saveName = fullfile(p.savePath, 'motionBlebsByIntensityManyPrctHistogramFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
    % plot protrusive minus retractive motion 
    f = figure;
    xCoord = (binWidth/2):binWidth:(binMax-binWidth/2);
    plot(xCoord, h.Values(0.5*(length(edges)-1)+1:end) - fliplr(h.Values(1:0.5*(length(edges)-1))), 'LineWidth', 2)
    hold on
    plot(xCoord, g.Values(0.5*(length(edges)-1)+1:end) - fliplr(g.Values(1:0.5*(length(edges)-1))), 'LineWidth', 2)
    legend({'> 90th intensity percentile', '< 10th intensity percentile'}); colormap(jet);
    xlabel('Motion (microns/minute)'); ylabel('Frequency Protrusive - Frequency Retractive Motion'); 
    title('Protrusive-Retractive Motion')
    saveName = fullfile(p.savePath, 'protrusiveMinusRetractiveIntensityFaces');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);
%     
%     f = figure;
%     xCoord = (-1*binMax+binWidth/2):binWidth:(binMax-binWidth/2);
%     plot(xCoord, 2*(g.Values-h.Values)./(g.Values+h.Values), 'LineWidth', 2)
%     xlabel('Motion (microns/minute)'); ylabel('< 10th intensity percentile - > 90th intensity percentile'); 
%     title('Normalized Low - High Intensity Motion')
%     saveName = fullfile(p.savePath, 'lowIntensityMinusHighIntensityNormalMotionFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
%     f = figure;
%     numBins = 100;
%     h = histogram(motionFaces(isProtrusionFaces==1 & intensityFaces>(meanIntensity+2*stdIntensity)), numBins, 'Normalization', 'probability');
%     hold on
%     histogram(motionFaces(isProtrusionFaces==1 & intensityFaces>=(meanIntensity-stdIntensity) & intensityFaces<(meanIntensity+stdIntensity)), h.BinEdges, 'Normalization', 'probability');
%     histogram(motionFaces(isProtrusionFaces==1 & intensityFaces<=(meanIntensity-2*stdIntensity)), h.BinEdges, 'Normalization', 'probability');
%     legend({'x > 2 std above mean intensity', '-1 < x < 1 std below mean intensity', 'x < -2 std below mean intensity'}); colormap(jet);
%     xlabel('Motion (microns/minute)'); ylabel('Frequency'); 
%     title('Motion on Blebs of Different Intensities (Faces)'); 
%     axis([-5 5 -inf inf])
%     saveName = fullfile(p.savePath, 'motionBlebsByIntensityMany2STDHistogramFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
%     
%     % plot as line plots rather than histograms
%     f = figure;
%     binWidth = 0.1; binMax = 5;
%     edges = -binMax:binWidth:binMax;
%     edgeCenters = (edges(1:end-1)+edges(2:end))/2;
%     veryVeryHighN = histcounts(motionFaces(isProtrusionFaces==1 & intensityFaces>(meanIntensity+1.5*stdIntensity)), edges, 'Normalization', 'probability');
%     %veryHighN = histcounts(motionFaces(isProtrusionFaces==1 & intensityFaces>(meanIntensity+2*stdIntensity) & intensityFaces<(meanIntensity+3*stdIntensity)), edges, 'Normalization', 'probability');
%     %highN = histcounts(motionFaces(isProtrusionFaces==1 & intensityFaces>(meanIntensity+stdIntensity) & intensityFaces<(meanIntensity+2*stdIntensity)), edges, 'Normalization', 'probability');
%     midN = histcounts(motionFaces(isProtrusionFaces==1 & intensityFaces>=(meanIntensity-1.5*stdIntensity) & intensityFaces<(meanIntensity+1.5*stdIntensity)), edges, 'Normalization', 'probability');
%     %lowN = histcounts(motionFaces(isProtrusionFaces==1 & intensityFaces<(meanIntensity-stdIntensity) & intensityFaces>(meanIntensity-2*stdIntensity)), edges, 'Normalization', 'probability');
%     %veryLowN = histcounts(motionFaces(isProtrusionFaces==1 & intensityFaces<(meanIntensity-2*stdIntensity) & intensityFaces>(meanIntensity-3*stdIntensity)), edges, 'Normalization', 'probability');
%     veryVeryLowN = histcounts(motionFaces(isProtrusionFaces==1 & intensityFaces<(meanIntensity-1.5*stdIntensity)), edges, 'Normalization', 'probability');
%     veryVeryHighN(length(edgeCenters)/2:length(edgeCenters)/2+1) = NaN;
%     %veryHighN(length(edgeCenters)/2:length(edgeCenters)/2+1) = NaN;
%     %highN(length(edgeCenters)/2:length(edgeCenters)/2+1) = NaN;
%     midN(length(edgeCenters)/2:length(edgeCenters)/2+1) = NaN;
%     %lowN(length(edgeCenters)/2:length(edgeCenters)/2+1) = NaN;
%     %veryLowN(length(edgeCenters)/2:length(edgeCenters)/2+1) = NaN;
%     veryVeryLowN(length(edgeCenters)/2:length(edgeCenters)/2+1) = NaN;
%     %edgeCenters(length(edgeCenters)/2:length(edgeCenters)/2+1) = [];
%     plot(edgeCenters, veryVeryHighN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     hold on
%     %plot(edgeCenters, veryHighN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     %plot(edgeCenters, highN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     plot(edgeCenters, midN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     %plot(edgeCenters, lowN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     %plot(edgeCenters, veryLowN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     plot(edgeCenters, veryVeryLowN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     %legend({'x > 3 std above mean intensity', '2 < x < 3 std below mean intensity','1 < x < 2 std below mean intensity', '-1 < x < 1 std below mean intensity', '-1 < x < -2 std below mean intensity', '-2 < x < -3 std below mean intensity','x < -3 std below mean intensity'});
%     legend({'x > 1.5 std above mean intensity', '-1.5 < x < 1.5 std below mean intensity', 'x < -1.5 std below mean intensity'});
%     colormap(parula);
%     xlabel('Motion (microns/minute)'); ylabel('Frequency'); 
%     title('Motion on Blebs of Different Intensities (Faces)'); 
%     axis([-5 5 -inf inf])
%     saveName = fullfile(p.savePath, 'motionBlebsByIntensityHistogramManyLinesFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
    % plot as line plots rather than histograms
    f = figure;
    binWidth = 0.1; binMax = 5;
    edges = -binMax:binWidth:binMax;
    edgeCenters = (edges(1:end-1)+edges(2:end))/2;
    protrusionsN = histcounts(motionFaces(isProtrusionFaces==1 & intensityFaces>(meanIntensity+stdIntensity)), edges, 'Normalization', 'probability');
    notProtrusionsN = histcounts(motionFaces(isProtrusionFaces==1 & intensityFaces<=(meanIntensity-stdIntensity)), edges, 'Normalization', 'probability');
    protrusionsN(length(edgeCenters)/2:length(edgeCenters)/2+1) = NaN;
    notProtrusionsN(length(edgeCenters)/2:length(edgeCenters)/2+1) = NaN;
    edgeCenters(length(edgeCenters)/2:length(edgeCenters)/2+1) = [];
    plot(edgeCenters, protrusionsN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
    hold on
    plot(edgeCenters, notProtrusionsN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
    legend({'> 1 std above mean intensity', '< 1 std below mean intensity'}); colormap(jet);
    xlabel('Motion (microns/minute)'); ylabel('Frequency'); 
    title('Motion on Blebs of Different Intensities (Faces)'); 
    axis([-5 5 -inf inf])
    saveName = fullfile(p.savePath, 'motionBlebsByIntensitySTDHistogramLinesFaces');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);

    f = figure;
    numBins = 64;
    h = histogram(meanMotionPatches(isProtrusionPatches==1 & meanIntensityPatches>mean(meanIntensityPatches(logical(isProtrusionPatches)))), numBins, 'Normalization', 'probability');
    hold on
    histogram(meanMotionPatches(isProtrusionPatches==1 & meanIntensityPatches<mean(meanIntensityPatches(logical(isProtrusionPatches)))), h.BinEdges, 'Normalization', 'probability');
    legend({'above mean intensity', 'below mean intensity'}); colormap(jet);
    xlabel('Motion (microns/minute)'); ylabel('Frequency'); 
    title('Motion of Blebs of Different Intensities (Patches)'); 
    axis([-5 5 -inf inf])
    saveName = fullfile(p.savePath, 'motionBlebsByIntensityMeanHistogramPatches');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);
end


%% Plot histograms of intensity for blebs of different motion (faces and patches)
if makeMotionPlots == 1
    f = figure;
    h = histogram(intensityFaces(isProtrusionFaces==1 & motionFaces>0), 64, 'Normalization', 'probability');
    hold on
    histogram(intensityFaces(isProtrusionFaces==1 & motionFaces<0), h.BinEdges, 'Normalization', 'probability');
    legend({'protruding', 'retracting'}); colormap(jet);
    xlabel('Normalized Intensity'); ylabel('Frequency');
    title('Intensity on Blebs with Different Motions (Faces)');
    saveName = fullfile(p.savePath, 'intensityBlebsByMotionHistogramFaces');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
%     f = figure;
%     h = histogram(meanIntensityPatches(isProtrusionPatches==1 & meanMotionPatches>0), 30, 'Normalization', 'probability');
%     hold on
%     histogram(meanIntensityPatches(isProtrusionPatches==1 & meanMotionPatches<0), h.BinEdges, 'Normalization', 'probability');
%     legend({'protruding', 'retracting'}); colormap(jet);
%     xlabel('Normalized Intensity'); ylabel('Frequency');
%     title('Intensity of Blebs with Different Motions (Patches)');
%     saveName = fullfile(p.savePath, 'intensityBlebsByMotionHistogramPatches');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);

end

%% Plot a histogram of face intensities for different motions (faces)
if makeMotionPlots == 1
    numBins = 64;
    f = figure;
    h = histogram(intensityFaces(motionFaces>0),numBins, 'Normalization', 'probability');
    hold on
    histogram(intensityFaces(motionFaces<0), h.BinEdges, 'Normalization', 'probability');
    legend({'protruding', 'retracting'}); colormap(jet);
    xlabel('Normalized Intensity'); ylabel('Frequency');
    title('Intensity of All Faces for Different Motions (Faces)');
    saveName = fullfile(p.savePath, 'intensityByMotionHistogramFaces');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);
end


% %% Make intensity-motion-curvature heatmaps (faces)
% if makeMotionPlots == 1
%     numGridPointsIntensity = 64; numGridPointsMotion = 512;
%     f = figure;
%     makeHeatmap(intensityFaces(isfinite(motionFaces)), motionFaces(isfinite(motionFaces)), numGridPointsIntensity, numGridPointsMotion);
%     axis([-Inf 2 -10 10]);
%     xlabel('Normalized Intensity'); ylabel('Motion (microns/minute)');
%     title('Motion vs. Intensity For All Faces')
%     saveName = fullfile(p.savePath, 'motionIntensityHeatmapFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
% end

% numGridPointsIntensity = 256; numGridPointsCurvature = 8*1024; %1024
% f = figure;
% makeHeatmap(intensityFaces, curvatureFaces, numGridPointsIntensity, numGridPointsCurvature);
% axis([-Inf 2 -0.5 0.5]);
% xlabel('Normalized Intensity'); ylabel('Mean Curvature'); 
% title('Curvature vs. Intensity For All Faces')
% saveName = fullfile(p.savePath, 'curvatureIntensityHeatmapFaces');
% saveas(f, saveName, 'epsc'); savefig(f, saveName);

% if makeMotionPlots == 1
%     numGridPointsCurvature = 1024; numGridPointsMotion = 512;
%     f = figure;
%     makeHeatmap(curvatureFaces(isfinite(motionFaces)), motionFaces(isfinite(motionFaces)), numGridPointsCurvature, numGridPointsMotion);
%     axis([-1 1 -10 10]);
%     xlabel('Curvature'); ylabel('Motion (microns/minute)');
%     title('Motion vs. Curvature For All Faces')
%     saveName = fullfile(p.savePath, 'motionCurvatureHeatmapFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
% end

% plot the distance transform data
if p.analyzeDistance == 1 
    
    % plot distances on all faces
    numGridPointsDistance = 64;
    distanceIndex = 1 + round((distanceFaces) ./ (max(distanceFaces(isfinite(distanceFaces))))*(numGridPointsDistance-1));
    distanceIndex(~isfinite(distanceIndex)) = NaN;
    meanIntensity = nan(1,numGridPointsDistance);
    for i = 1:numGridPointsDistance
        meanIntensity(1,i) = nanmean(intensityFaces(distanceIndex==i));
    end
    f = figure;
    xOffset = (1/(2*numGridPointsDistance) )*(max(distanceFaces(isfinite(distanceFaces))));
    plot(linspace(0, max(distanceFaces(isfinite(distanceFaces))), numGridPointsDistance) + xOffset, meanIntensity, 'LineWidth', 2)
    axis([0 5 -Inf Inf])
    xlabel('Distance from bleb edge'); ylabel('Mean Intensity')
    title('Mean Intensity as a Function of Distance from Bleb Edge For All Faces (microns)');
    saveName = fullfile(p.savePath, 'intensityFunctionOfDistanceFaces');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
%     % plot distances on and off blebs
%     numGridPointsDistance = 64;
%     distanceIndex = 1 + round((distanceFaces) ./ (max(distanceFaces(isfinite(distanceFaces))))*(numGridPointsDistance-1));
%     distanceIndex(~isfinite(distanceIndex)) = NaN;
%     meanIntensityOnBlebs = nan(1,numGridPointsDistance);
%     meanIntensityOffBlebs = nan(1,numGridPointsDistance);
%     for i = 1:numGridPointsDistance
%         meanIntensityOnBlebs(1,i) = nanmean(intensityFaces(distanceIndex==i & isProtrusionFaces==1));
%         meanIntensityOffBlebs(1,i) = nanmean(intensityFaces(distanceIndex==i & isProtrusionFaces==0));
%     end
%     f = figure;
%     xOffset = (1/(2*numGridPointsDistance) )*(max(distanceFaces(isfinite(distanceFaces))));
%     plot(linspace(0, max(distanceFaces(isfinite(distanceFaces))), numGridPointsDistance) + xOffset, meanIntensityOnBlebs, 'LineWidth', 2)
%     hold on
%     plot(linspace(0, max(distanceFaces(isfinite(distanceFaces))), numGridPointsDistance) + xOffset, meanIntensityOffBlebs, 'LineWidth', 2)
%     axis([0 5 -Inf Inf])
%     xlabel('Distance from bleb edge'); ylabel('Mean Intensity')
%     title('Mean Intensity as a Function of Distance from Bleb Edge on and off Blebs');
%     legend('On blebs', 'Off blebs');
%     saveName = fullfile(p.savePath, 'intensityFunctionOfDistanceBlebsFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
%     
end
% 
% % plot the probability of being on a bleb as a function of intensity
% numGridPointsIntensity = 128;
% intensityIndex = 1 + round((intensityFaces - min(intensityFaces)) ./ (max(intensityFaces)-min(intensityFaces))*(numGridPointsIntensity-1));
% meanBlebby = nan(1,numGridPointsIntensity);
% for i = 1:numGridPointsIntensity
%     meanBlebby(1,i) = nanmean(isProtrusionFaces(intensityIndex==i));
% end
% f = figure;
% plot(linspace(min(intensityFaces), max(intensityFaces), numGridPointsIntensity), meanBlebby, 'LineWidth', 2)
% ylabel('Probability of being on a bleb'); xlabel('Intensity (a.u.)')
% title('Blebbiness as a Function of Surface Intensity For All Faces');
% saveName = fullfile(p.savePath, 'blebbyFunctionOfIntensityFaces');
% saveas(f, saveName, 'epsc'); savefig(f, saveName);


%% Plot histograms of volume-intensity relationships for blebs (patches)
numBins = 15;
meanIntensity = mean(meanIntensityPatches(logical(isProtrusionPatches)));
f = figure;
h = histogram(volumePatches(isProtrusionPatches==1 & meanIntensityPatches>meanIntensity), numBins, 'Normalization', 'probability');
hold on
histogram(volumePatches(isProtrusionPatches==1 & meanIntensityPatches<=meanIntensity), h.BinEdges, 'Normalization', 'probability');
axis([0 60 -Inf Inf]);
legend({'above mean intensity', 'below mean intensity'}); colormap(jet);
xlabel('Volume (cubic microns)'); ylabel('Frequency'); 
title('Volume of Blebs of Different Intensities (Patches)'); 
saveName = fullfile(p.savePath, 'volumeBlebsByIntensityHistogramPatches');
saveas(f, saveName, 'epsc'); savefig(f, saveName);

% numBins = 16;
% meanVolume = mean(volumePatches(logical(isProtrusionPatches)));
% figure;
% h = histogram(meanIntensityPatches(isProtrusionPatches==1), numBins, 'Normalization', 'probability');
% f = figure;
% histogram(meanIntensityPatches(isProtrusionPatches==1 & volumePatches>meanVolume), h.BinEdges, 'Normalization', 'probability');
% hold on
% histogram(meanIntensityPatches(isProtrusionPatches==1 & volumePatches<=meanVolume), h.BinEdges, 'Normalization', 'probability');
% legend({'above mean volume', 'below mean volume'}); colormap(jet);
% xlabel('Normalized Intensity'); ylabel('Frequency'); 
% title('Mean intensity of Blebs of Different Volumes (Patches)'); 
% saveName = fullfile(p.savePath, 'intensityBlebsByVolumeHistogramPatches');
% saveas(f, saveName, 'epsc'); savefig(f, saveName);

% % plot as line plots rather than histograms
% f = figure; % good for pip2
% binWidth = 0.06; binMax = 1.98;
% edges = 0:binWidth:binMax;
% edgeCenters = (edges(1:end-1)+edges(2:end))/2;
% volumeHigh = histcounts(meanIntensityPatches(isProtrusionPatches==1 & volumePatches>meanVolume), edges, 'Normalization', 'probability');
% volumeLow = histcounts(meanIntensityPatches(isProtrusionPatches==1 & volumePatches<=meanVolume), edges, 'Normalization', 'probability');
% plot(edgeCenters, volumeHigh, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
% hold on
% plot(edgeCenters, volumeLow, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
% legend({'> mean volume', '< mean volume'}); colormap(jet);
% xlabel('Intensity'); ylabel('Frequency');
% title('Intensity on Blebs of different volumes (Patches)');
% %axis([-5 5 -inf inf])
% saveName = fullfile(p.savePath, 'volumeBlebsHistogramLinesPatches');
% saveas(f, saveName, 'epsc'); savefig(f, saveName);

% numBins = 32;
% volumeBlebs = volumePatches(logical(isProtrusionPatches));
% volume10 = prctile(volumeBlebs, 10);
% volume90 = prctile(volumeBlebs, 90);
% f = figure;
% h = histogram(meanIntensityPatches(isProtrusionPatches==1 & volumePatches>volume90), numBins, 'Normalization', 'probability');
% hold on
% %histogram(meanIntensityPatches(isProtrusionPatches==1 & volumePatches<volume90 & volumePatches>=volume10 ), h.BinEdges, 'Normalization', 'probability');
% hold on
% histogram(meanIntensityPatches(isProtrusionPatches==1 & volumePatches<=volume10), h.BinEdges, 'Normalization', 'probability');
% legend({'> 90th percentile', '< 10th percentile'}); colormap(jet);
% xlabel('Normalized Intensity'); ylabel('Frequency'); 
% title('Mean intensity of Blebs of Different Volumes (Patches)'); 
% saveName = fullfile(p.savePath, 'intensityBlebsByVolumeHistogramPercentilePatches');
% saveas(f, saveName, 'epsc'); savefig(f, saveName);

% numBins = 32; % good for pip2
% volume10 = prctile(volumePatches, 10);
% volume90 = prctile(volumePatches, 90);
% f = figure;
% h = histogram(meanIntensityPatches(volumePatches>volume90), numBins, 'Normalization', 'probability');
% hold on
% %histogram(meanIntensityPatches(volumePatches<volume90 & volumePatches>=volume10 ), h.BinEdges, 'Normalization', 'probability');
% hold on
% histogram(meanIntensityPatches(volumePatches<=volume10), h.BinEdges, 'Normalization', 'probability');
% legend({'> 90th percentile', '< 10th percentile'}); colormap(jet);
% xlabel('Normalized Intensity'); ylabel('Frequency'); 
% title('Mean intensity of ALL PATCHES of Different Volumes (Patches)'); 
% saveName = fullfile(p.savePath, 'intensityPatchesByVolumeHistogramPercentilePatches');
% saveas(f, saveName, 'epsc'); savefig(f, saveName);

%% Plot histograms of volume-motion relationships for blebs (patch)
numBins = 20; 
if makeMotionPlots == 1
    meanVolume = mean(volumePatches(logical(isProtrusionPatches)));
    f = figure;
    h = histogram(meanMotionPatches(isProtrusionPatches==1 & volumePatches>meanVolume), numBins, 'Normalization', 'probability');
    hold on
    histogram(meanMotionPatches(isProtrusionPatches==1 & volumePatches<=meanVolume), h.BinEdges, 'Normalization', 'probability');
    legend({'above mean volume', 'below mean volume'}); colormap(jet);
    xlabel('Motion (microns/minute)'); ylabel('Frequency'); 
    title('Mean motion of Blebs of Different Volumes (Patches)');
    axis([-4 4 0 Inf]);
    saveName = fullfile(p.savePath, 'intensityBlebsByVolumeHistogramPatches');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);
end


% %% Make an intensity-volume heatmap for blebs (patches)
% numGridPointsIntensity = 64; numGridPointsVolume = 512;
% f = figure;
% makeHeatmap(meanIntensityPatches(isProtrusionPatches==1), volumePatches(isProtrusionPatches==1), numGridPointsIntensity, numGridPointsVolume);
% axis([-Inf Inf 0 0.4*10^4]);
% xlabel('Normalized Intensity'); ylabel('Volume'); 
% title('Volume vs. Mean Intensity For Blebs (Patches)')
% saveName = fullfile(p.savePath, 'volumeIntensityBlebsHeatmapPatches');
% saveas(f, saveName, 'epsc'); savefig(f, saveName);


%% Plot polarization statistics
if p.analyzeVonMises == 1
    
    [numTotalRand,~] = size(vonMisesBlebsRand);
    [numTotalFrames,~] = size(vonMisesBlebs);
    
%     % plot bleb-intensity correlation statistics
%     binEdges = -1:0.1:1;
%     blebIntensityDirection = sum(vonMisesBlebs(:,1:3).*vonMisesIntensity(:,1:3), 2);
%     blebRandIntensityDirection = sum(vonMisesBlebsRand(:,1:3).*repelem(vonMisesIntensity(:,1:3), numTotalRand/numTotalFrames, 1),2);
%     f = figure;
%     h = histogram(blebRandIntensityDirection, binEdges, 'Normalization', 'probability');
%     hold on
%     histogram(blebIntensityDirection, h.BinEdges, 'Normalization', 'probability');
%     legend({'blebs permutation control', 'blebs-intensity direction correlation'}); colormap(jet);
%     xlabel('Correlation'); ylabel('Frequency'); 
%     title('Bleb polarization - Intensity polarization directional correlation');
%     saveName = fullfile(p.savePath, 'blebsIntensityDirectionDotVonMises');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
    % plot as line plots rather than histograms
    f = figure; % good for pip2
    binWidth = 0.02; binMax = 1;
    edges = -binMax:binWidth:binMax;
    edgeCenters = (edges(1:end-1)+edges(2:end))/2;
    blebIntensityDirection = histcounts(sum(vonMisesBlebs(:,1:3).*vonMisesIntensity(:,1:3), 2), edges, 'Normalization', 'probability');
    blebRandIntensityDirection = histcounts(sum(vonMisesBlebsRand(:,1:3).*repelem(vonMisesIntensity(:,1:3), numTotalRand/numTotalFrames, 1),2), edges, 'Normalization', 'probability');
    plot(edgeCenters, blebIntensityDirection, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
    hold on
    plot(edgeCenters, blebRandIntensityDirection, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
    legend({'bleb-intensity', 'control'}); colormap(jet);
    xlabel('Directional Correlation'); ylabel('Frequency');
    title('Directional Correlation');
    %axis([-5 5 -inf inf])
    saveName = fullfile(p.savePath, 'blebsIntensityDirectionDotVonMisesLines');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
%     % plot as cumsum line plots rather than line plots
%     f = figure; % good for pip2
%     binWidth = 0.02; binMax = 1;
%     edges = -binMax:binWidth:binMax;
%     edgeCenters = (edges(1:end-1)+edges(2:end))/2;
%     blebIntensityDirection = histcounts(sum(vonMisesBlebs(:,1:3).*vonMisesIntensity(:,1:3), 2), edges, 'Normalization', 'probability');
%     blebRandIntensityDirection = histcounts(sum(vonMisesBlebsRand(:,1:3).*repelem(vonMisesIntensity(:,1:3), numTotalRand/numTotalFrames, 1),2), edges, 'Normalization', 'probability');
%     plot(edgeCenters, cumsum(blebIntensityDirection), 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     hold on
%     plot(edgeCenters, cumsum(blebRandIntensityDirection), 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     legend({'bleb-intensity', 'control'}); colormap(jet);
%     xlabel('Directional Correlation'); ylabel('Frequency Sum');
%     title('Cummulative Directional Correlation');
%     %axis([-5 5 -inf inf])
%     saveName = fullfile(p.savePath, 'blebsIntensityDirectionDotVonMisesCumLines');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
%     % plot bleb-negCurvature correlation statistics
%     binEdges = -1:0.1:1; % 0.02
%     blebCurvatureDirection = sum(vonMisesBlebs(:,1:3).*vonMisesNegCurvature(:,1:3), 2);
%     blebRandCurvatureDirection = sum(vonMisesBlebsRand(:,1:3).*repelem(vonMisesNegCurvature(:,1:3), numTotalRand/numTotalFrames, 1),2);
%     f = figure;
%     h = histogram(blebRandCurvatureDirection, binEdges, 'Normalization', 'probability');
%     hold on
%     histogram(blebCurvatureDirection, h.BinEdges, 'Normalization', 'probability');
%     legend({'blebs permutation control', 'blebs-neg curvature direction correlation'}); colormap(jet);
%     xlabel('Correlation'); ylabel('Frequency'); 
%     title('Bleb polarization - Neg Curvature polarization directional correlation');
%     saveName = fullfile(p.savePath, 'blebsNegCurvatureDirectionDotVonMises');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
%     % plot bleb-intensityMin correlation statistics
%     blebIntensityMinDirection = sum(vonMisesBlebs(:,1:3).*vonMisesIntensityMin(:,1:3), 2);
%     blebRandIntensityMinDirection = sum(vonMisesBlebsRand(:,1:3).*repelem(vonMisesIntensityMin(:,1:3), numTotalRand/numTotalFrames, 1),2);
%     f = figure;
%     h = histogram(blebRandIntensityMinDirection, numBins, 'Normalization', 'probability');
%     hold on
%     histogram(blebIntensityMinDirection, h.BinEdges, 'Normalization', 'probability');
%     legend({'blebs permutation control', 'blebs-intensityMin direction correlation'}); colormap(jet);
%     xlabel('Correlation'); ylabel('Frequency'); 
%     title('Bleb polarization - IntensityMin polarization directional correlation');
%     saveName = fullfile(p.savePath, 'blebsIntensityMinDirectionDotVonMises');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
end

% %% Make intensity barplots for blebs and nonblebs (faces)
% numPermRepeats = 20;
% f = figure;
% meanBlebIntensity = mean(intensityFaces(isProtrusionFaces==1));
% meanNonBlebIntensity = mean(intensityFaces(isProtrusionFaces==0));
% disp('Comparing Bleb and NonBleb Intensities (Faces)')
% [~, tP] = ttest2(intensityFaces(isProtrusionFaces==1), intensityFaces(isProtrusionFaces==0));
% [~, ksP] = kstest2(intensityFaces(isProtrusionFaces==1), intensityFaces(isProtrusionFaces==0));
% permP = max([permTestDifMeanOneSided(intensityFaces(isProtrusionFaces==1), intensityFaces(isProtrusionFaces==0), numPermRepeats) 1/numPermRepeats]);
% disp(['  ttest p-value: ' num2str(tP)]);
% disp(['  kstest p-value: ' num2str(ksP)]);
% disp(['  permtest p-value: ' num2str(permP)]);
% disp(['  number of faces: ' num2str(length(intensityFaces))]);
% bar([0 1], [meanBlebIntensity meanNonBlebIntensity], 'FaceColor', 'w', 'LineWidth', 2);
% hold on
% errorbar([0 1], [meanBlebIntensity meanNonBlebIntensity], [std(intensityFaces(isProtrusionFaces==1)) std(intensityFaces(isProtrusionFaces==0))], 'LineStyle', 'none', 'LineWidth', 2, 'Color', 'k');
% set(gca,'XTickLabel', {'Blebby Faces', 'Non-blebby Faces'});
% ylabel('Mean Intensity (error bar is std)')
% title('Mean Intensities On and Off Blebs (Faces)')
% saveName = fullfile(p.savePath, 'intensityBlebsBarplotFaces');
% saveas(f, saveName, 'epsc'); savefig(f, saveName);

% % make a bar plot of the high intensity and low-mid faces only
% stdCutoff = 1;
% meanIntensity = mean(intensityFaces); stdIntensity = std(intensityFaces);
% blebHigh = intensityFaces(isProtrusionFaces==1 & intensityFaces > meanIntensity+stdCutoff*stdIntensity);
% nonBlebHigh = intensityFaces(isProtrusionFaces==0 & intensityFaces > meanIntensity+stdCutoff*stdIntensity);
% blebLow = intensityFaces(isProtrusionFaces==1 & intensityFaces <= meanIntensity-stdCutoff*stdIntensity);
% nonBlebLow = intensityFaces(isProtrusionFaces==0 & intensityFaces <= meanIntensity-stdCutoff*stdIntensity);
% f = figure;
% bar([0 1], 100*[length(blebHigh) length(nonBlebHigh)]./(length(blebHigh)+length(nonBlebHigh)), 'FaceColor', 'w', 'LineWidth', 2);
% set(gca,'XTickLabel', {'Blebby Faces', 'Non-blebby Faces'});
% ylabel('Percentage')
% title(['Percentage Blebby/Non-blebby > ' num2str(stdCutoff) ' std above the mean intensity(Faces)'])
% saveName = fullfile(p.savePath, 'percentBlebsHighIntensityBarplotFaces');
% saveas(f, saveName, 'epsc'); savefig(f, saveName);
% f = figure;
% bar([0 1], 100*[length(blebLow) length(nonBlebLow)]./(length(blebLow)+length(nonBlebLow)), 'FaceColor', 'w', 'LineWidth', 2);
% set(gca,'XTickLabel', {'Blebby Faces', 'Non-blebby Faces'});
% ylabel('Percentage')
% title(['Percentage Blebby/Non-blebby <= ' num2str(stdCutoff) ' std below the mean intensity(Faces)'])
% saveName = fullfile(p.savePath, 'percentBlebsLowIntensityBarplotFaces');
% saveas(f, saveName, 'epsc'); savefig(f, saveName);


% %% Make intensity barplots for blebs and nonblebs (patches)
% numPermRepeats = 100;
% f = figure;
% meanBlebIntensity = mean(meanIntensityPatches(isProtrusionPatches==1))
% stdErrorBlebIntensity = std(meanIntensityPatches(isProtrusionPatches==1))/sqrt(length(meanIntensityPatches(isProtrusionPatches==1)))
% meanNonBlebIntensity = mean(meanIntensityPatches(isProtrusionPatches==0))
% stdErrorNonBlebIntensity = std(meanIntensityPatches(isProtrusionPatches==0))/sqrt(length(meanIntensityPatches(isProtrusionPatches==0)))
% disp('Comparing Bleb and NonBleb Intensities , Mean (Patches)');
% [~, tP] = ttest2(meanIntensityPatches(isProtrusionPatches==1), meanIntensityPatches(isProtrusionPatches==0)); 
% disp(['  ttest p-value: ' num2str(tP)]); 
% [~, ksP] = kstest2(meanIntensityPatches(isProtrusionPatches==1), meanIntensityPatches(isProtrusionPatches==0)); 
% disp(['  kstest p-value: ' num2str(ksP)]);
% permP = max([permTestDifMeanOneSided(meanIntensityPatches(isProtrusionPatches==1), meanIntensityPatches(isProtrusionPatches==0), numPermRepeats) 1/numPermRepeats]);
% disp(['  permTest one-sided dif in the means p-value is < or = to ' num2str(permP)]);
% disp(['  number of patches: ' num2str(length(meanIntensityPatches))]);
% bar([0 1], [meanBlebIntensity meanNonBlebIntensity], 'FaceColor', 'w', 'LineWidth', 2);
% hold on
% errorbar([0 1], [meanBlebIntensity meanNonBlebIntensity], [std(meanIntensityPatches(isProtrusionPatches==1)) std(meanIntensityPatches(isProtrusionPatches==0))], 'LineStyle', 'none', 'LineWidth', 2, 'Color', 'k');
% set(gca,'XTickLabel', {'Blebs', 'Non-blebs'});
% ylabel('Mean Intensity (error bar is std)')
% title('Mean Intensities On and Off Blebs , Mean (Patches)')
% saveName = fullfile(p.savePath, 'intensityBlebsBarplotMeanPatches');
% saveas(f, saveName, 'epsc'); savefig(f, saveName);

% % make a bar plot of the high intensity and low-mid faces
% stdCutoff = 0;
% meanIntensity = mean(meanIntensityPatches); stdIntensity = mean(meanIntensityPatches);
% blebHigh = meanIntensityPatches(isProtrusionPatches==1 & meanIntensityPatches > meanIntensity+stdCutoff*stdIntensity);
% nonBlebHigh = meanIntensityPatches(isProtrusionPatches==0 & meanIntensityPatches > meanIntensity+stdCutoff*stdIntensity);
% blebLow = meanIntensityPatches(isProtrusionPatches==1 & meanIntensityPatches <= meanIntensity+stdCutoff*stdIntensity);
% nonBlebLow = meanIntensityPatches(isProtrusionPatches==0 & meanIntensityPatches <= meanIntensity+stdCutoff*stdIntensity);
% f = figure;
% bar([0 1], 100*[length(blebHigh) length(nonBlebHigh)]./(length(blebHigh)+length(nonBlebHigh)), 'FaceColor', 'w', 'LineWidth', 2);
% set(gca,'XTickLabel', {'Blebs', 'Non-blebs'});
% ylabel('Percentage')
% title(['Percentage Blebby/Non-blebby > ' num2str(stdCutoff) ' std above the mean intensity (Patches)'])
% saveName = fullfile(p.savePath, 'percentBlebsHighIntensityBarplotPatches');
% saveas(f, saveName, 'epsc'); savefig(f, saveName);
% f = figure;
% bar([0 1], 100*[length(blebLow) length(nonBlebLow)]./(length(blebLow)+length(nonBlebLow)), 'FaceColor', 'w', 'LineWidth', 2);
% set(gca,'XTickLabel', {'Blebs', 'Non-blebs'});
% ylabel('Percentage')
% title(['Percentage Blebby/Non-blebby <= ' num2str(stdCutoff) ' std below the mean intensity (Patches)'])
% saveName = fullfile(p.savePath, 'percentBlebsLowIntensityBarplotPatches');
% saveas(f, saveName, 'epsc'); savefig(f, saveName);

% numPermRepeats = 100;
% f = figure;
% meanBlebIntensity = mean(maxIntensityPatches(isProtrusionPatches==1));
% meanNonBlebIntensity = mean(maxIntensityPatches(isProtrusionPatches==0));
% disp('Comparing Bleb and NonBleb Intensities, Max (Patches)');
% [~, tP] = ttest2(maxIntensityPatches(isProtrusionPatches==1), maxIntensityPatches(isProtrusionPatches==0)); 
% disp(['  ttest p-value: ' num2str(tP)]); 
% [~, ksP] = kstest2(maxIntensityPatches(isProtrusionPatches==1), maxIntensityPatches(isProtrusionPatches==0)); 
% disp(['  kstest p-value: ' num2str(ksP)]);
% permP = max([permTestDifMeanOneSided(maxIntensityPatches(isProtrusionPatches==1), maxIntensityPatches(isProtrusionPatches==0), numPermRepeats) 1/numPermRepeats]);
% disp(['  permTest one-sided dif in the means p-value is < or = to ' num2str(permP)]);
% disp(['  number of patches: ' num2str(length(maxIntensityPatches))]);
% bar([0 1], [meanBlebIntensity meanNonBlebIntensity], 'FaceColor', 'w', 'LineWidth', 2);
% hold on
% errorbar([0 1], [meanBlebIntensity meanNonBlebIntensity], [std(meanIntensityPatches(isProtrusionPatches==1)) std(meanIntensityPatches(isProtrusionPatches==0))], 'LineStyle', 'none', 'LineWidth', 2, 'Color', 'k');
% set(gca,'XTickLabel', {'Blebs', 'Non-blebs'});
% ylabel('Mean Intensity (error bar is std)')
% title('Mean Intensities On and Off Blebs, Max (Patches)')
% saveName = fullfile(p.savePath, 'intensityBlebsBarplotMaxPatches');
% saveas(f, saveName, 'epsc'); savefig(f, saveName);


%% Plot bleb densities at various intensities (Faces)
if p.analyzeDiffusion == 1
    meanIntensity = mean(intensityFaces); stdIntensity = mean(intensityFaces);
    
%     % plot the diffusion of bleb density
%     numBins = 30; 
%     stdCutoff = 0;
%     meanIntensity = mean(intensityFaces); stdIntensity = std(intensityFaces);
%     blebDensityAtHighIntensity = diffusedProtrusionsFaces(intensityFaces > meanIntensity+stdCutoff*stdIntensity);
%     blebDensityAtLowIntensity = diffusedProtrusionsFaces(intensityFaces < meanIntensity-stdCutoff*stdIntensity); % !!!!!!
%     f = figure;
%     g = histogram(blebDensityAtHighIntensity, numBins, 'Normalization', 'probability', 'DisplayStyle', 'Stairs');
%     hold on
%     h = histogram(blebDensityAtLowIntensity, g.BinEdges, 'Normalization', 'probability', 'DisplayStyle', 'Stairs');
%     legend('High Intensity', 'Low Intensity')
%     xlabel('Normalized Bleb Density');
%     ylabel('Frequency');
%     title(['Bleb Density at Intensities ' num2str(stdCutoff) ' std above and below the mean (Faces)'])
%     saveName = fullfile(p.savePath, 'blebDensityByIntensityStepsMeanFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
%     % make a "probability" plot of intensity vs bleb density
%     f = figure;
%     probHighIntensity = g.Values./(h.Values + g.Values);
%     binLoc = (h.BinEdges(1:end-1) + h.BinEdges(2:end))/2;
%     cmap = lines(2);
%     fill([binLoc(1) binLoc binLoc(end)], [0 probHighIntensity 0], cmap(1,:), 'LineStyle', 'none')
%     hold on
%     fill([binLoc(1) binLoc binLoc(end)], [1 probHighIntensity 1], cmap(2,:), 'LineStyle', 'none')
%     axis([0 1 0 1])
%     legend('High Intensity', 'Low Intensity')
%     xlabel('Normalized Bleb Density')
%     ylabel('Probability of High Intensity')
%     title('Probability of being high intensity as a function of bleb density')
%     saveName = fullfile(p.savePath, 'intensityBlebDensityProbabilityMeanFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
    % plot the diffusion of bleb density
    numBins = 30;
    stdCutoff = 1;
    meanIntensity = mean(intensityFaces); stdIntensity = std(intensityFaces);
    blebDensityAtHighIntensity = diffusedProtrusionsFaces(intensityFaces > meanIntensity+stdCutoff*stdIntensity);
    blebDensityAtLowIntensity = diffusedProtrusionsFaces(intensityFaces < meanIntensity-stdCutoff*stdIntensity); % !!!!!!
    f = figure;
    g = histogram(blebDensityAtHighIntensity, numBins, 'Normalization', 'probability', 'DisplayStyle', 'Stairs');
    hold on
    h = histogram(blebDensityAtLowIntensity, g.BinEdges, 'Normalization', 'probability', 'DisplayStyle', 'Stairs');
    legend('High Intensity', 'Low Intensity')
    xlabel('Normalized Bleb Density');
    ylabel('Frequency');
    title(['Bleb Density at Intensities ' num2str(stdCutoff) ' std above and below the mean (Faces)'])
    saveName = fullfile(p.savePath, 'blebDensityByIntensityStepsSTDFaces');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);
%     
%     % make a "probability" plot of intensity vs bleb density
%     f = figure;
%     probHighIntensity = g.Values./(h.Values + g.Values);
%     binLoc = (h.BinEdges(1:end-1) + h.BinEdges(2:end))/2;
%     cmap = lines(2);
%     fill([binLoc(1) binLoc binLoc(end)], [0 probHighIntensity 0], cmap(1,:), 'LineStyle', 'none')
%     hold on
%     fill([binLoc(1) binLoc binLoc(end)], [1 probHighIntensity 1], cmap(2,:), 'LineStyle', 'none')
%     axis([0 1 0 1])
%     legend('High Intensity', 'Low Intensity')
%     xlabel('Normalized Bleb Density')
%     ylabel('Probability of High Intensity')
%     title('Probability of being high intensity as a function of bleb density')
%     saveName = fullfile(p.savePath, 'intensityBlebDensityProbabilitySTDFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
%     % plot the diffusion of bleb density
%     numBins = 30;
%     stdCutoff = 2;
%     meanIntensity = mean(intensityFaces); stdIntensity = std(intensityFaces);
%     blebDensityAtHighIntensity = diffusedProtrusionsFaces(intensityFaces > meanIntensity+stdCutoff*stdIntensity);
%     blebDensityAtLowIntensity = diffusedProtrusionsFaces(intensityFaces < meanIntensity-stdCutoff*stdIntensity); % !!!!!!
%     f = figure;
%     g = histogram(blebDensityAtHighIntensity, numBins, 'Normalization', 'probability', 'DisplayStyle', 'Stairs');
%     hold on
%     h = histogram(blebDensityAtLowIntensity, g.BinEdges, 'Normalization', 'probability', 'DisplayStyle', 'Stairs');
%     legend('High Intensity', 'Low Intensity')
%     xlabel('Normalized Bleb Density');
%     ylabel('Frequency');
%     title(['Bleb Density at Intensities ' num2str(stdCutoff) ' std above and below the mean (Faces)'])
%     saveName = fullfile(p.savePath, 'blebDensityByIntensityStepsSTD2Faces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
%     
%     % make a "probability" plot of intensity vs bleb density
%     f = figure;
%     probHighIntensity = g.Values./(h.Values + g.Values);
%     binLoc = (h.BinEdges(1:end-1) + h.BinEdges(2:end))/2;
%     cmap = lines(2);
%     fill([binLoc(1) binLoc binLoc(end)], [0 probHighIntensity 0], cmap(1,:), 'LineStyle', 'none')
%     hold on
%     fill([binLoc(1) binLoc binLoc(end)], [1 probHighIntensity 1], cmap(2,:), 'LineStyle', 'none')
%     axis([0 1 0 1])
%     legend('High Intensity', 'Low Intensity')
%     xlabel('Normalized Bleb Density')
%     ylabel('Probability of High Intensity')
%     title('Probability of being high intensity as a function of bleb density')
%     saveName = fullfile(p.savePath, 'intensityBlebDensityProbabilitySTD2Faces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
%     % plot the diffusion of the SVM score
%     stdCutoff = 1; 
%     meanIntensity = mean(intensityFaces); stdIntensity = std(intensityFaces);
%     blebDensityAtHighIntensity = diffusedSVMFaces(intensityFaces > meanIntensity+stdCutoff*stdIntensity);
%     blebDensityAtLowIntensity = diffusedSVMFaces(intensityFaces < meanIntensity-stdCutoff*stdIntensity); % !!!!!!!!!!
%     f = figure;
%     g = histogram(blebDensityAtHighIntensity, 45, 'Normalization', 'probability', 'DisplayStyle', 'Stairs');
%     hold on
%     h = histogram(blebDensityAtLowIntensity, g.BinEdges, 'Normalization', 'probability', 'DisplayStyle', 'Stairs');
%     legend('High Intensity', 'Low Intensity')
%     xlabel('Normalized diffusion of SVM score');
%     ylabel('Frequency');
%     title(['SVM Diffusion at Intensities ' num2str(stdCutoff) ' std above and below the mean(Faces)'])
%     saveName = fullfile(p.savePath, 'SVMdiffusionByIntensityStepsFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
%     % make a "probability" plot of intensity vs bleb density
%     f = figure;
%     probHighIntensity = g.Values./(h.Values + g.Values);
%     binLoc = (h.BinEdges(1:end-1) + h.BinEdges(2:end))/2;
%     cmap = lines(2);
%     fill([binLoc(1) binLoc binLoc(end)], [0 probHighIntensity 0], cmap(1,:), 'LineStyle', 'none')
%     hold on
%     fill([binLoc(1) binLoc binLoc(end)], [1 probHighIntensity 1], cmap(2,:), 'LineStyle', 'none')
%     axis([0 1 0 1])
%     legend('High Intensity', 'Low Intensity')
%     xlabel('Normalized SVM Diffusion')
%     ylabel('Probability of High Intensity')
%     title('Probability of being high intensity as a function of SVM Diffusion')
%     saveName = fullfile(p.savePath, 'intensitySVMdiffusionProbabilityFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
%     
%     % plot a curvature vs bleb density heat map
%     numGridPointsBlebDiffusion = 64; numGridPointsCurvature = 2*1024; %1024
%     f = figure;
%     makeHeatmap(diffusedProtrusionsFaces, curvatureFaces, numGridPointsBlebDiffusion, numGridPointsCurvature);
%     %axis([-Inf 2 -0.5 0.5]);
%     xlabel('Normalized Bleb Density'); ylabel('Mean Curvature');
%     title('Curvature vs. Bleb Density For All Faces')
%     saveName = fullfile(p.savePath, 'curvatureBlebDensityHeatmapFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
%     
%     % plot an intensity vs bleb density heat map
%     numGridPointsBlebDiffusion = 64; numGridPointsIntensity = 64; %1024
%     f = figure;
%     makeHeatmap(diffusedProtrusionsFaces, intensityFaces, numGridPointsBlebDiffusion, numGridPointsIntensity);
%     %axis([-Inf 2 -0.5 0.5]);
%     xlabel('Normalized Bleb Density'); ylabel('Intensity');
%     title('Intensity vs. Bleb Density For All Faces')
%     saveName = fullfile(p.savePath, 'intensityBlebDensityHeatmapFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
%     
%     % plot as line plots rather than a heatmap
%     f = figure;
%     binWidth = 0.04; binMax = 1;
%     edges = 0:binWidth:binMax;
%     edgeCenters = (edges(1:end-1)+edges(2:end))/2;
%     veryVeryHighN = histcounts(diffusedProtrusionsFaces(curvatureFaces>0.5), edges, 'Normalization', 'probability');
%     midN = histcounts(diffusedProtrusionsFaces(curvatureFaces>=(-0.5) & curvatureFaces<0.5), edges, 'Normalization', 'probability');
%     veryVeryLowN = histcounts(diffusedProtrusionsFaces(curvatureFaces<(-0.5)), edges, 'Normalization', 'probability');
%     plot(edgeCenters, veryVeryHighN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     hold on
%     plot(edgeCenters, midN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     plot(edgeCenters, veryVeryLowN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     legend({' > 0.5 mean curvature', '-0.5 < x < 0.5 mean curvature', ' < -0.5 mean curvature'});
%     colormap(parula);
%     xlabel('Bleb Density'); ylabel('Frequency'); 
%     title('Bleb Density at different curvatures (Faces)'); 
%     saveName = fullfile(p.savePath, 'blebDensityByCurvatureHistogramManyLinesFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
%     
%     % plot as line plots rather than a heatmap
%     f = figure;
%     binWidth = 0.04; binMax = 1;
%     edges = 0:binWidth:binMax;
%     edgeCenters = (edges(1:end-1)+edges(2:end))/2;
%     veryVeryHighN = histcounts(diffusedProtrusionsFaces(curvatureFaces>1), edges, 'Normalization', 'probability');
%     midN = histcounts(diffusedProtrusionsFaces(curvatureFaces>=(-1) & curvatureFaces<1), edges, 'Normalization', 'probability');
%     veryVeryLowN = histcounts(diffusedProtrusionsFaces(curvatureFaces<(-1)), edges, 'Normalization', 'probability');
%     plot(edgeCenters, veryVeryHighN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     hold on
%     plot(edgeCenters, midN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     plot(edgeCenters, veryVeryLowN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     legend({' > 1 mean curvature', '-1 < x < 1 mean curvature', ' < -1 mean curvature'});
%     colormap(parula);
%     xlabel('Bleb Density'); ylabel('Frequency'); 
%     title('Bleb Density at different curvatures (Faces)'); 
%     saveName = fullfile(p.savePath, 'blebDensityByCurvatureHistogramManyLinesFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
%     % plot as line plots rather than a heatmap
%     f = figure;
%     binWidth = 0.04; binMax = 1;
%     edges = 0:binWidth:binMax;
%     edgeCenters = (edges(1:end-1)+edges(2:end))/2;
%     veryVeryHighN = histcounts(diffusedProtrusionsFaces(intensityFaces>1.1), edges, 'Normalization', 'probability');
%     midN = histcounts(diffusedProtrusionsFaces(intensityFaces>=(0.9) & intensityFaces<1.1), edges, 'Normalization', 'probability');
%     veryVeryLowN = histcounts(diffusedProtrusionsFaces(intensityFaces<(0.9)), edges, 'Normalization', 'probability');
%     plot(edgeCenters, veryVeryHighN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     hold on
%     plot(edgeCenters, midN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     plot(edgeCenters, veryVeryLowN, 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12)
%     legend({' > 1.1 intensity', '0.9 < x < 1.1 intensity', ' < 0.9 intensity'});
%     colormap(parula);
%     xlabel('Bleb Density'); ylabel('Frequency'); 
%     title('Bleb Density at different intensities (Faces)'); 
%     saveName = fullfile(p.savePath, 'blebDensityByIntensityHistogramManyLinesFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
    
end


% plots showing analysis of the other channel
if p.analyzeOtherChannel == 1
    
    % plot the intensityOther distribution
    numBins = 64;
    f = figure;
    h = histogram(intensityOtherFaces(isProtrusionFaces==1), numBins);
    hold on
    histogram(intensityOtherFaces(isProtrusionFaces==0), h.BinEdges);
    legend({'bleb', 'nonBleb'}); colormap(jet);
    xlabel('Normalized IntensityOther'); ylabel('Count');
    title('IntensityOther on Blebs and Non-Blebs, Non-normalized, (Faces)');
    saveName = fullfile(p.savePath, 'intensityOtherBlebsNonNormalHistogramFaces');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
    f = figure; 
    h = histogram(intensityOtherFaces(isProtrusionFaces==1), numBins, 'Normalization', 'probability');
    hold on
    histogram(intensityOtherFaces(isProtrusionFaces==0), h.BinEdges, 'Normalization', 'probability');
    legend({'bleb', 'nonBleb'}); colormap(jet);
    xlabel('Normalized IntensityOther'); ylabel('Frequency');
    title('IntensityOther on Blebs and Non-Blebs (Faces)');
    saveName = fullfile(p.savePath, 'intensityOtherBlebsHistogramFaces');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
    %% Make intensity-intensityOther scatterplots (patches)
%     f = figure;
%     cmap = colormap(hsv(length(p.cellsList)));
%     cmap = colormap(makeColormap('div_spectral', length(p.cellsList)));
%     for i = 1:length(cellIndexPatches)
%         plot(meanIntensityOtherPatches(i), meanIntensityPatches(i), 'Color', cmap(cellIndexPatches(i),:), 'LineStyle', 'none', 'Marker', '.', 'MarkerSize', 5);
%         hold on
%     end
%     xlabel('Normalized Intensity Other'); ylabel('Normalized Intensity Channel');
%     title('Intensity Other - IntensityOther Scatterplot, All patches (Patches)');
%     axis equal
%     saveName = fullfile(p.savePath, 'intensityIntensityOtherScatterplotPatches');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
    f = figure;
    cmap = colormap(hsv(length(p.cellsList)));
    cmap = colormap(makeColormap('div_spectral', length(p.cellsList)));
    for i = 1:length(cellIndexPatches)
        if isProtrusionPatches(i) == 1
            plot(meanIntensityPatches(i), meanIntensityOtherPatches(i), 'Color', cmap(cellIndexPatches(i),:), 'LineStyle', 'none', 'Marker', '.', 'MarkerSize', 5);
            hold on
        end
    end
    xlabel('Normalized Intensity'); ylabel('Normalized Intensity Other Channel');
    title('IntensityOther - Intensity Scatterplot, Only Blebs (Patches)');
    axis equal
    saveName = fullfile(p.savePath, 'intensityIntensityOtherBlebsScatterplotPatches');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
%     f = figure;
%     cmap = colormap(hsv(length(p.cellsList)));
%     cmap = colormap(makeColormap('div_spectral', length(p.cellsList)));
%     for i = 1:length(cellIndexPatches)
%         if isProtrusionPatches(i) == 0
%             plot(meanIntensityOtherPatches(i), meanIntensityPatches(i), 'Color', cmap(cellIndexPatches(i),:), 'LineStyle', 'none', 'Marker', '.', 'MarkerSize', 5);
%             hold on
%         end
%     end
%     xlabel('Normalized Intensity Other'); ylabel('Normalized Intensity Channel');
%     title('IntensityOther - Intensity Scatterplot, Only Non-Blebs (Patches)');
%     axis equal
%     saveName = fullfile(p.savePath, 'intensityIntensityOtherNonBlebsScatterplotPatches');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
    
    %% Plot histograms of volume-intensityOther relationships for blebs (patches)
    meanIntensityOther = mean(meanIntensityOtherPatches(logical(isProtrusionPatches)));
    f = figure;
    h = histogram(volumePatches(isProtrusionPatches==1 & meanIntensityOtherPatches>meanIntensityOther), 64, 'Normalization', 'probability');
    hold on
    histogram(volumePatches(isProtrusionPatches==1 & meanIntensityOtherPatches<=meanIntensityOther), h.BinEdges, 'Normalization', 'probability');
    legend({'above mean intensityOther', 'below mean intensityOther'}); colormap(jet);
    xlabel('Volume (cubic microns)'); ylabel('Frequency');
    title('Volume of Blebs of Different IntensityOthers (Patches)');
    saveName = fullfile(p.savePath, 'volumeByIntensityOtherBlebsHistogramPatches');
    saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
%     meanVolume = mean(volumePatches(logical(isProtrusionPatches)));
%     f = figure;
%     h = histogram(meanIntensityOtherPatches(isProtrusionPatches==1 & volumePatches>meanVolume), 16, 'Normalization', 'probability');
%     hold on
%     histogram(meanIntensityOtherPatches(isProtrusionPatches==1 & volumePatches<=meanVolume), h.BinEdges, 'Normalization', 'probability');
%     legend({'above mean volume', 'below mean volume'}); colormap(jet);
%     xlabel('Normalized IntensityOther'); ylabel('Frequency');
%     title('Mean IntensityOther of Blebs of Different Volumes (Patches)');
%     saveName = fullfile(p.savePath, 'intensityOtherByVolumeBlebsHistogramPatches');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);
    
%     
%     %% Make intensity-motion-curvature heatmaps (faces)
%     numGridPointsIntensity = 20; numGridPointsIntensityOther = 65;
%     f = figure;
%     makeHeatmap(intensityFaces, intensityOtherFaces, numGridPointsIntensity, numGridPointsIntensityOther);
%     xlabel('Normalized Intensity'); ylabel('Normalized IntensityOther (microns/minute)');
%     title('IntensityOther vs. Intensity For All Faces (Faces)')
%     axis equal
%     saveName = fullfile(p.savePath, 'intensityOtherIntensityHeatmapFaces');
%     saveas(f, saveName, 'epsc'); savefig(f, saveName);

end




%% test the difference between two distributions' means via a permutation test
function pValue = permTestDifMeanOneSided(distOne, distTwo, numRepeats)

% tests if distOne has a higher mean than distTwo

% relabel the distributions as smallerDist and largerDist
if length(distOne) < length(distTwo)
    smallDist = distOne;
    largeDist = distTwo;
else
    smallDist = distTwo;
    largeDist = distOne;
end

% finds the size of the distributions
smallDistSize = length(smallDist);
largeDistSize = length(largeDist);

% find  the mean of the smallDist
meanSmallDist = mean(smallDist);

% find numRepeats differences in the mean
difInMeanDifs = nan(1,length(numRepeats));
for i = 1:numRepeats
    
    % estimate the actual difference in the mean
    permLarge = largeDist(randperm(largeDistSize, smallDistSize));
    meanLargeDist = mean(permLarge);
    actualMeanDif = meanLargeDist-meanSmallDist;
    
    % estimate the differance of the mean in the permuted distributions
    permLarge = largeDist(randperm(largeDistSize, smallDistSize));
    combinedDist = [permLarge, smallDist];
    combinedDist = combinedDist(randperm(length(combinedDist))); % randomize the order of combinedDist
    permMeanDif = mean(combinedDist(1:length(combinedDist)/2)) - mean(combinedDist(length(combinedDist)/2:end));
    
    % find the differance in the mean diferances
    difInMeanDifs(i) = actualMeanDif-permMeanDif;
end

% convert smallDist and largeDist back to distOne and distTwo for the one-sided test
if length(distTwo) > length(distOne)
    difInMeanDifs = -1*difInMeanDifs;
end

% calculate the p-value
pValue = 1-mean(difInMeanDifs>0);
