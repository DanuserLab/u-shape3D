function validateBlebClassifier(p)

% validateBlebClassifier - plot various validations for the bleb classifier
%
% NOTE: You must have run the process blebDetect on the data to calculate
%       statistics
%
% p.mainDirectory - the directory within which clickPathList directories
%                   are contained
%
% p.clicksPathList - a cell array of the directories with training, the 
%                    directories are assumed to contain the output of 
%                    clickOnBlebs.m
% 
% p.MDsPathList - a cell array of the directories of the MovieData objects
%                 corresponding to p.clicksPathList
%
% p.saveDirectory - the directory where the SVM was saved
%
% p.saveNameCells - the name of the set of saved protrusion data 
%
% p.saveNameModel - the name of the SVM model
%
% p.usePatchMerge - set to 1 to use data from the PatchMerge process rather
%                   than the SurfaceSegment process
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


% load the list of clickedOnProtrusions indices (this is just to avoid generating this variable twice)
load(fullfile(p.saveDirectory,[p.saveNameCells '.mat']));

% if usePatchMerge is undefined, define it
if ~isfield(p, 'usePatchMerge')
    p.usePatchMerge = 0;
end

% iterate through the click paths
blebClickedOn = []; blebNotClickedOn = []; notBlebClickedOn = []; notBlebNotClickedOn = [];
modelOn = []; clickedOn = []; clickIndex =[]; measures = []; meanClickedOnCell = []; meanModelOnCell = []; meanModelPercentage = []; percentClickedOnCertain = [];
for c = 1:length(p.clicksPathList)
    
    % load the raw bleb location and other clicker data
    locationsPath = fullfile(p.mainDirectory, p.clicksPathList{c}, 'blebLocs.mat');
    load(locationsPath);  % loads frameIndex, chanIndex, and locations{}
    
    % determine what clickMode was used to select protrusions
    if isfield(locations{1}, 'blebs') && isfield(locations{1}, 'notBlebs')
        clickMode = 'certainBlebs';
    elseif isfield(locations{1}, 'notBlebs')
        clickMode = 'allNotBlebs';
    else
        clickMode = 'allBlebs';
    end
    
    % load the movieData object
    try
        mdName = dir(fullfile(p.mainDirectory, p.MDsPathList{c}, '*.mat'));
        load(fullfile(p.mainDirectory, p.MDsPathList{c}, mdName.name));
    catch
        disp('The provided MD path is not the path to a Matlab variable');
    end
    
    % determine the channel index
    meshProcessIndex = MD.packages_{1}.getProcessIndexByName('Mesh3DProcess');
    chan = MD.packages_{1}.processes_{meshProcessIndex}.funParams_.channels(1);
    if strcmp(chan, 'a'), chan = 1; end
    chanIndex = chan*ones(length(frameIndex), 1);
    
    % setup paths to data 
    analysisPath = fullfile(p.mainDirectory, p.MDsPathList{c}, 'Morphology', 'Analysis');
    deconParamPath = fullfile(analysisPath,'Parameters', 'deconParameters.mat');
    if p.usePatchMerge == 1
        surfaceSegmentPath = fullfile(analysisPath,'PatchMerge', 'ch1');
    else
        surfaceSegmentPath = fullfile(analysisPath,'SurfaceSegment', 'ch1');
    end
    
    % load the surface segmentation statistics
    try
        csStatStruct = load(fullfile(analysisPath, 'PatchDescribe', 'segmentStats.mat'));
    catch % for backwards compatability
        csStatStruct = load(fullfile(analysisPath, 'BlebSegment', 'segmentStats.mat'));
    end
    stats = csStatStruct.segmentStats; cellStats = csStatStruct.cellStats;
    
    % load the SVM model
    mStruct = load(fullfile(p.saveDirectory,[p.saveNameModel '.mat']));
    inModel = mStruct.inModelAll;
    SVMmodel = mStruct.SVMmodelAll;
    
    % load the decon parameters
    saveP = p; load(deconParamPath); p = saveP;
    if ~exist('weinerEstimateList', 'var'), weinerEstimateList = ones(1,MD.nFrames_); end

    % iterate through the frames
    for f = 1:length(frameIndex)
        
        % load the surface segmentation
        csStruct = load(fullfile(surfaceSegmentPath, sprintf('surfaceSegment_%i_%i.mat', chanIndex(f), frameIndex(f))));
        if p.usePatchMerge == 0
            blebSegment = csStruct.surfaceSegment;
            segmentedRegions = unique(csStruct.surfaceSegment);
        else
            blebSegment = csStruct.surfaceSegmentPatchMerge;
            segmentedRegions = unique(csStruct.surfaceSegmentPatchMerge);
        end
        segmentedRegions = unique(segmentedRegions(segmentedRegions>0));
        
        % assemble matrices of measures
        measuresCell = makeMeasuresMatrixSVM(stats, cellStats, inModel, weinerEstimateList, chanIndex(f), frameIndex(f), MD.pixelSize_);
        
        % make predictions using the model
        [label,~] = predict(SVMmodel, measuresCell);
        
        % parse the predictions
        numPatches = length(unique(blebSegment(blebSegment>0)));
        for i = 1:length(stats{chanIndex(f),frameIndex(f)}.index)
            if label(i) == 0
                blebSegment(blebSegment==stats{chanIndex(f),frameIndex(f)}.index(i)) = 0;
            end
        end
        classifiedBlebs = unique(blebSegment);
        classifiedBlebs = unique(classifiedBlebs(classifiedBlebs>0));
        numBlebs = length(classifiedBlebs);
        
        % iterate through the segmented regions
        clickedOnCell = nan(1,length(segmentedRegions));
        modelOnCell = nan(1,length(segmentedRegions));
        clickIndexCell = c*ones(1,length(segmentedRegions));
        for s = 1:length(segmentedRegions)
            
            % if it was selected as a bleb and classified as a bleb
            if ( (strcmp(clickMode, 'allNotBlebs') && ~ismember(segmentedRegions(s), clickedOnNotProtrusions{c,1}{f,1})) || (~strcmp(clickMode, 'allNotBlebs') && ismember(segmentedRegions(s), clickedOnProtrusions{c,1}{f,1})) ) && ismember(segmentedRegions(s), classifiedBlebs)
               blebClickedOn = [blebClickedOn, segmentedRegions(s)];
               modelOnCell(s) = 1; clickedOnCell(s) = 1;
            
            % if it was selected as a bleb and not classified as a bleb
            elseif ( (strcmp(clickMode, 'allNotBlebs') && ~ismember(segmentedRegions(s), clickedOnNotProtrusions{c,1}{f,1})) || (~strcmp(clickMode, 'allNotBlebs') && ismember(segmentedRegions(s), clickedOnProtrusions{c,1}{f,1})) ) && ~ismember(segmentedRegions(s), classifiedBlebs)
               notBlebClickedOn = [notBlebClickedOn, segmentedRegions(s)];
               modelOnCell(s) = 0; clickedOnCell(s) = 1;
               
            % if it was not selected as a bleb (or selected as certainly not a bleb) and classified as a bleb
            elseif ( (strcmp(clickMode, 'allBlebs') && ~ismember(segmentedRegions(s), clickedOnProtrusions{c,1}{f,1})) || ismember(segmentedRegions(s), clickedOnNotProtrusions{c,1}{f,1}) ) && ismember(segmentedRegions(s), classifiedBlebs)
               blebNotClickedOn = [blebNotClickedOn, segmentedRegions(s)];
               modelOnCell(s) = 1; clickedOnCell(s) = 0;
            
            % if it was not selected as a bleb (or selected as not a bleb) and not classified as a bleb   
            elseif ( (strcmp(clickMode, 'allBlebs') && ~ismember(segmentedRegions(s), clickedOnProtrusions{c,1}{f,1})) || ismember(segmentedRegions(s), clickedOnNotProtrusions{c,1}{f,1}) ) && ~ismember(segmentedRegions(s), classifiedBlebs)
                notBlebNotClickedOn = [notBlebNotClickedOn, segmentedRegions(s)];
                modelOnCell(s) = 0; clickedOnCell(s) = 0;
                
            else
                if strcmp(clickMode, 'allBlebs') || strcmp(clickMode, 'allNotBlebs')
                    disp(['Warning: region ' num2str(s) 'should occupy a location on the confusion matrix'])
                end
            end    
        end
        
        % gather data to assess feature relevence
        assert(length(modelOnCell) == size(measuresCell,1), 'measuresCell and modelOnCell have different sizes');
        modelOn = [modelOn, modelOnCell];
        clickedOn = [clickedOn, clickedOnCell];
        clickIndex = [clickIndex, clickIndexCell];
        measures = [measures; measuresCell];
        
        % assemble a list of patch percentages clicked on for allBlebs and allNotBlebs
        meanClickedOnCell = [meanClickedOnCell, mean(clickedOnCell)];
        meanModelOnCell = [meanModelOnCell, mean(modelOnCell)];
        
        % assemble a list of patch percentages for the certain clickMode
        meanModelPercentage = [meanModelPercentage, numBlebs/numPatches];
        
        % calculate the percentage of patches clicked on in certain mode
        percentClickedOnCertain = [percentClickedOnCertain, sum(isfinite(clickedOnCell))/length(clickedOnCell)];
        
    end  
end

% display confusion matrix data for all the cells
totalNum = length(blebClickedOn) + length(notBlebClickedOn) + length(blebNotClickedOn) + length(notBlebNotClickedOn);
disp('   training on all of the data')
disp(['      true positives: ' num2str(100*length(blebClickedOn)/totalNum)])
disp(['      true negatives: ' num2str(100*length(notBlebNotClickedOn)/totalNum)])
disp(['      false positives: ' num2str(100*length(blebNotClickedOn)/totalNum)])
disp(['      false negatives: ' num2str(100*length(notBlebClickedOn)/totalNum)])
precision = length(blebClickedOn)/(length(blebClickedOn) + length(blebNotClickedOn));
disp(['      precision: ' num2str(100*precision)])
recall = length(blebClickedOn)/(length(blebClickedOn) + length(notBlebClickedOn));
disp(['      recall: ' num2str(100*recall)])
disp(['      F1 score: ' num2str(100*2*precision*recall/(precision+recall))])

% display percentage clicked on and identified as protrusions
if strcmp(clickMode, 'allBlebs') || strcmp(clickMode, 'allNotBlebs')
    disp([  '   mean percentage of patches selected by user: ' num2str(100*mean(meanClickedOnCell)) ' +-(std) ' num2str(100*std(meanClickedOnCell))]);
    disp([  '   mean percentage of patches selected by model: ' num2str(100*mean(meanModelOnCell)) ' +-(std) ' num2str(100*std(meanModelOnCell))]);
else
    disp([  '   mean percentage of patches classified as protrusive: ' num2str(100*mean(meanModelPercentage)) ' +-(std) ' num2str(100*std(meanModelPercentage))]);
    disp([  '   mean percentage of patches clicked on: ' num2str(100*mean(percentClickedOnCertain)) ' +-(std) ' num2str(100*std(percentClickedOnCertain))]);
end

% remove nan's and their corresponding measures from clickedOn to deal with the two click modes
newMeasures = [];
for m = 1:size(measures,1)
    if isfinite(clickedOn(m))
        newMeasures = [newMeasures; measures(m,:)];
    end    
end
measures = newMeasures;
clickIndex(~isfinite(clickedOn)) = [];
clickedOn(~isfinite(clickedOn)) = [];

% perform a k-fold cross validation randomly across blebs
k = 10; numReps = 5;
falseNegative = zeros(1, numReps); falsePositive = zeros(1, numReps);
truePositive = zeros(1, numReps); trueNegative = zeros(1, numReps); 
for r = 1:numReps
    
    % display progress
    %disp(['... ' num2str(k) ' -fold cross validation: ' num2str(r) ' of ' num2str(numReps)]);
    
    % select training and test partitions
    randVector = rand(1, length(clickedOn));
    randVector = randVector > 1/k;
    trainBlebs = clickedOn(randVector);
    testBlebs = clickedOn(~randVector);
    trainMeasures = measures(randVector,:);
    testMeasures = measures(~randVector,:);
    
    % train on the training data
    [model, inModel, ~] = svmWithFeatureSelection(trainMeasures, trainBlebs', 1, 1);
    
    % select the test measures that are in the model
    selectedTestMeasures = [];
    for m = 1:length(inModel)
        if inModel(m) == 1
            selectedTestMeasures = [selectedTestMeasures, testMeasures(:,m)];
        end
    end
    
    % predict the test classes from the training data
    [testPredict, ~] = predict(model, selectedTestMeasures);
    
    % find the percentage error
    falseNegative(r) = sum(testBlebs'==1 & testPredict==0)/length(testBlebs);
    falsePositive(r) = sum(testBlebs'==0 & testPredict==1)/length(testBlebs); 
    truePositive(r) = sum(testBlebs'==1 & testPredict==1)/length(testBlebs);
    trueNegative(r) = sum(testBlebs'==0 & testPredict==0)/length(testBlebs);
end

disp(['   ' num2str(k) '-fold cross validation with ' num2str(numReps) ' shuffles'])
disp(['      true positives: ' num2str(100*mean(truePositive))])
disp(['      true negatives: ' num2str(100*mean(trueNegative))])
disp(['      false positives: ' num2str(100*mean(falsePositive))])
disp(['      false negatives: ' num2str(100*mean(falseNegative))])
precision = mean(truePositive)/(mean(truePositive) + mean(falsePositive));
disp(['      precision: ' num2str(100*precision)])
recall = mean(truePositive)/(mean(truePositive) + mean(falseNegative));
disp(['      recall: ' num2str(100*recall)])
disp(['      F1 score: ' num2str(100*2*precision*recall/(precision+recall))])

% perform a jack-knife across cells
falseNegative = zeros(1, length(p.clicksPathList)); falsePositive = zeros(1, length(p.clicksPathList));
truePositive = zeros(1, length(p.clicksPathList)); trueNegative = zeros(1, length(p.clicksPathList));
for c = 1:length(p.clicksPathList)
    
    % display progress
    %disp([' ... jackknife: ' num2str(c) ' of ' num2str(length(p.clicksPathList))]);
    
    % select training and test partitions
    clickVector = (clickIndex==c);
    trainBlebs = clickedOn(~clickVector);
    testBlebs = clickedOn(clickVector);
    trainMeasures = measures(~clickVector,:);
    testMeasures = measures(clickVector,:);
    
    % train on the training data
    [model, inModel, ~] = svmWithFeatureSelection(trainMeasures, trainBlebs', 1, 1);
    
    % select the test measures that are in the model
    selectedTestMeasures = [];
    for m = 1:length(inModel)
        if inModel(m) == 1
            selectedTestMeasures = [selectedTestMeasures, testMeasures(:,m)];
        end
    end
    
    % predict the test classes from the training data
    [testPredict, ~] = predict(model, selectedTestMeasures);
    
    % find the percentage error
    falseNegative(c) = sum(testBlebs'==1 & testPredict==0)/length(testBlebs); 
    falsePositive(c) = sum(testBlebs'==0 & testPredict==1)/length(testBlebs); 
    truePositive(c) = sum(testBlebs'==1 & testPredict==1)/length(testBlebs);
    trueNegative(c) = sum(testBlebs'==0 & testPredict==0)/length(testBlebs);
end

disp(['   jackknife with ' num2str(length(p.clicksPathList)) ' cells'])
disp(['      true positives: ' num2str(100*mean(truePositive))])
disp(['      true negatives: ' num2str(100*mean(trueNegative))])
disp(['      false positives: ' num2str(100*mean(falsePositive))])
disp(['      false negatives: ' num2str(100*mean(falseNegative))])
precision = mean(truePositive)/(mean(truePositive) + mean(falsePositive));
disp(['      precision: ' num2str(100*precision)])
recall = mean(truePositive)/(mean(truePositive) + mean(falseNegative));
disp(['      recall: ' num2str(100*recall)])
disp(['      F1 score: ' num2str(100*2*precision*recall/(precision+recall))])

% compare, via the dice coefficient, models from different subsets of cells
numTrainingCells = 1; % normally these should be larger
numTestCells = 1;
numCompares = 3;
dice = nan(1,numCompares);
for n = 1:numCompares
    
    % display progress
    %disp([' ... comparison: ' num2str(n) ' of ' num2str(numCompares)]);
    
    % randomly select cells
    assert(2*numTrainingCells+numTestCells <= length(p.clicksPathList), 'the training and test set sizes are too large to select from the click paths without overlap');
    rng('shuffle');
    randCells = randperm(length(p.clicksPathList), 2*numTrainingCells+numTestCells);
    
    % select training and test partitions
    trainIndices1 = ismember(clickIndex, randCells(1:numTrainingCells));
    trainIndices2 = ismember(clickIndex, randCells((numTrainingCells+1):(2*numTrainingCells)));
    testIndices = ismember(clickIndex, randCells((2*numTrainingCells):end));
    trainBlebs1 = clickedOn(trainIndices1);
    trainBlebs2 = clickedOn(trainIndices2);
    trainMeasures1 = measures(trainIndices1,:);
    trainMeasures2 = measures(trainIndices2,:);
    testMeasures = measures(testIndices,:);
    
    % train on the training data
    [model1, inModel1, ~] = svmWithFeatureSelection(trainMeasures1, trainBlebs1', 1, 1);
    [model2, inModel2, ~] = svmWithFeatureSelection(trainMeasures2, trainBlebs2', 1, 1);
    
    % select the test measures that are in model1
    selectedTestMeasures1 = [];
    for m = 1:length(inModel1)
        if inModel1(m) == 1
            selectedTestMeasures1 = [selectedTestMeasures1, testMeasures(:,m)];
        end
    end
    
    % select the test measures that are in model2
    selectedTestMeasures2 = [];
    for m = 1:length(inModel2)
        if inModel2(m) == 1
            selectedTestMeasures2 = [selectedTestMeasures2, testMeasures(:,m)];
        end
    end
    
    % predict the test classes from the training data
    [testPredict1, ~] = predict(model1, selectedTestMeasures1);
    [testPredict2, ~] = predict(model2, selectedTestMeasures2);
  
    % calculate the Dice coefficient 
    dice(n) = 2*(sum((testPredict1 == 1) & (testPredict1 == testPredict2)))/(sum(testPredict1)+sum(testPredict2));
end
disp(['   self-similiarity with training sets of size ' num2str(numTrainingCells) ' and test set of size ' num2str(numTestCells) ])
disp(['      mean dice coefficient: ' num2str(100*mean(dice))])
disp(['      std dice coefficient: ' num2str(100*std(dice))])
disp(['      stderr dice coefficient: ' num2str(100*std(dice)/sqrt(length(dice)))])


% % plot a confusion matrix for the jackknife
% confusion(1,1) = mean(truePositive);
% confusion(1,2) = mean(falseNegative);
% confusion(2,1) = mean(falsePositive);
% confusion(2,2) = mean(trueNegative);
% figure; imagesc(confusion); colormap(hot(256)); colorbar; 
% title('Confusion Matrix (jackknife)');
