function runKrasTrain()

% runKrasTrain - for the three kras-labeled cells provided as example images, train an SVM to detect blebs
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

% Note: The completed cell analysis, up through the surfaceSegment and
% patchDescribe processes is assumed to have been run. (patchMerge
% and patchDescribeForMerge should not be run for bleb detection.) That
% analysis is assumed to be stored in Cell1, Cell2, and Cell3
% subdirectories within the analysis directory defined below. Although if 
% it is not, you can modify the p.cellsList below.
%
% This function will save an SVM bleb model, 'SVMtestKras', in the
% motifModelDirectory specified below. To use this model to detect blebs,
% uncomment out the line that sets motifDetect.svmPath in
% runKrasBlebSegment.


%% Set Directories
analysisDirectory = 'C:\Users\bsterling\Desktop\ZebrafishScripted\Analysis\';
motifModelDirectory = 'C:\Users\bsterling\Desktop\ZebrafishScripted\Analysis\Cell1\Morphology\svmModels\';


%% Generate training data
% set Kras cells to click on
p.cellsList{1} = 'Cell1';
%p.cellsList{2} = 'Cell2';
%p.cellsList{3} = 'Cell3';

% set parameters for generating training data (see the documentation of clickOnBlebs.m for more information)
p.mainDirectory = analysisDirectory;
p.clickMode = 'clickOnCertain';
p.nameOfClicker = 'TestClicker';
p.classNames = {'blebs'};
p.mode = 'continue'; % use 'restart' to click on every cell every time, use 'continue' to only click on unclicked on cells
p.surfaceMode = 'surfaceSegment';
p.framesPerCell = 1;

% generate training data
clickOnProtrusions(p)

%load('C:\Users\bsterling\Desktop\ZebrafishScripted\Analysis\Cell1\TrainingData\TestClicker\blebLocs.mat');

%% Train and validate an SVM motif classifier
p.MDsPathList{1} = p.cellsList{1};  
p.clicksPathList{1} = fullfile(p.MDsPathList{1}, 'TrainingData', p.nameOfClicker);
%p.MDsPathList{2} = p.cellsList{2};  p.clicksPathList{2} = fullfile(p.MDsPathList{2}, 'TrainingData', p.nameOfClicker);
%p.MDsPathList{3} = p.cellsList{3};  p.clicksPathList{3} = fullfile(p.MDsPathList{3}, 'TrainingData', p.nameOfClicker);
p.saveNameModel = 'SVMtestKras';
p.saveNameCells = 'testKrasCells';
p.mainDirectory = analysisDirectory;
p.saveDirectory = motifModelDirectory;

% train the classifier
disp('Training the classifier')
trainProtrusionsClassifier(p);

% validate the classifier
%validateBlebClassifier(p);