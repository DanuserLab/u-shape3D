function [model, inModel, fsHistory] = svmWithFeatureSelection(features, classes, reproducible, numReps)

% svmWithFeatureSelection - train an svm after feature selection
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

% optionally seed the random number generator
if reproducible == 1
    rng(536);
end

% determine the number of classes
numClasses = length(unique(classes));
assert(numClasses > 1, 'There must be at least two classes');

% perform a sequential feature selection
if numClasses == 2 % you might want to increase the number of reps
    [inModel, fsHistory] = sequentialfs(@critFun, features, classes, 'direction', 'backward', 'mcreps', numReps);
    %[inModel, fsHistory] = sequentialfs(@critFun, features, classes, 'direction', 'forward', 'mcreps', numReps);
else 
    [inModel, fsHistory] = sequentialfs(@critFunMulti, features, classes, 'direction', 'backward', 'mcreps', numReps);
end
    

% select the picked features
selectedFeatures = [];
for m = 1:length(inModel)
    if inModel(m) == 1
        selectedFeatures = [selectedFeatures, features(:,m)];
    end
end
% numFeatures = size(features,2);
% inModel = ones(numFeatures); fsHistory = [];

% send to SVM
if numClasses == 2
    model = fitcsvm(selectedFeatures, classes, 'KernelFunction', 'linear', 'Standardize', true);
    %model = fitcsvm(selectedFeatures, classes, 'KernelFunction', 'rbf', 'Standardize', true);
else
    template = templateSVM('KernelFunction', 'linear', 'BoxConstraint', 1, 'Standardize', 1);
    model = fitcecoc(selectedFeatures, classes, 'Learners', template, 'Coding', 'onevsone');
end


% a function that is inputted to the sequential feature selection function 
function numError = critFun(xTrain, yTrain, xTest, yTest)

% train a model
SVMModel = fitcsvm(xTrain, yTrain, 'KernelFunction', 'linear', 'Standardize', true);
%SVMModel = fitcsvm(xTrain, yTrain, 'KernelFunction', 'rbf', 'Standardize', true);

% predict the text values
[label, ~] = predict(SVMModel, xTest);

% calculate the number of errors
numError = sum(abs(label - yTest));


% a function that is inputted to the sequential feature selection function for more than two classes 
function numError = critFunMulti(xTrain, yTrain, xTest, yTest)

% train a model
template = templateSVM('KernelFunction', 'linear', 'BoxConstraint', 1, 'Standardize', 1);
%trainedClassifier = fitcecoc(predictors, response, 'Learners', template, 'Coding', 'onevsone', 'PredictorNames', {'decayingIntensityNAs' 'edgeAdvanceSpeedNAs' 'advanceSpeedNAs' 'lifeTimeNAs' 'meanIntensityNAs' 'distToEdgeFirstNAs' 'startingIntensityNAs' 'distToEdgeChangeNAs' 'distToEdgeLastNAs' 'edgeAdvanceDistLastChangeNAs' 'maxEdgeAdvanceDistChangeNAs'}, 'ResponseName', 'Group', 'ClassNames', totalGroups');
SVMModel = fitcecoc(xTrain, yTrain, 'Learners', template, 'Coding', 'onevsone');

% predict the text values
[label, ~] = predict(SVMModel, xTest);

% calculate the number of errors
numError = sum(double(logical(label - yTest)));

