%analyzeRSSI
%
%this function takes the data stored in lab-x and outside-x files and
%analyzes them in terms of % error.

%store the outdoor training and testing data

%get the error using the mean filter outdoors
trainingData=loadWithMeanFilter('../data/outside2-1.mat');
trainingData=[trainingData;loadWithMeanFilter('../data/outside2-2.mat')];
trainingData=[trainingData;loadWithMeanFilter('../data/outside2-4.mat')];
trainingData=[trainingData;loadWithMeanFilter('../data/outside2-5.mat')];
testingData=loadWithMeanFilter('../data/outside2-3.mat');

n=24;
defaultCoeffs = [-0.5*ones(2*n,1); zeros(2*n,1)];
meanFilterCoeffs = estimateCalibCoefficients(trainingData,defaultCoeffs);
figure
[avgError, percentErrors, absoluteErrors] =calibrateAndPlot(testingData, meanFilterCoeffs);
disp(' ')
h=get(gca,'title');
t=get(h,'string');
title(['Outdoors2: Density Plot of Distance Estimates: ' t])
disp('Mean Filter Outdoors: ')
disp(['  average percent error: ' num2str(mean(100*percentErrors)) '%'])
disp(['  average absolute error: ' num2str(mean(abs(absoluteErrors))) 'cm'])
disp(' ')
figure
subplot(2,1,1)
hist(100*percentErrors)
xlabel('Percent Error (%)')
ylabel('Number of Times Occurred')
title(['Outdoors2: Histogram of percent error'])
subplot(2,1,2)
hist(absoluteErrors)
xlabel('Absolute Error (cm)')
ylabel('Number of Times Occurred')
title(['Outdoors2: Histogram of absolute error'])


%get the error using the mean filter outdoors
trainingData=loadWithMeanFilter('../data/outside-1.mat');
trainingData=[trainingData;loadWithMeanFilter('../data/outside-2.mat')];
trainingData=[trainingData;loadWithMeanFilter('../data/outside-3.mat')];
trainingData=[trainingData;loadWithMeanFilter('../data/outside-4.mat')];
testingData=loadWithMeanFilter('../data/outside-5.mat');

n=16;
defaultCoeffs = [-0.5*ones(2*n,1); zeros(2*n,1)];
meanFilterCoeffs = estimateCalibCoefficients(trainingData,defaultCoeffs);
figure
[avgError, percentErrors, absoluteErrors] =calibrateAndPlot(testingData, meanFilterCoeffs);
disp(' ')
h=get(gca,'title');
t=get(h,'string');
title(['Outdoors: Density Plot of Distance Estimates: ' t])
disp('Mean Filter Outdoors: ')
disp(['  average percent error: ' num2str(mean(100*percentErrors)) '%'])
disp(['  average absolute error: ' num2str(mean(abs(absoluteErrors))) 'cm'])
disp(' ')
figure
subplot(2,1,1)
hist(100*percentErrors)
xlabel('Percent Error (%)')
ylabel('Number of Times Occurred')
title(['Outdoors: Histogram of percent error'])
subplot(2,1,2)
hist(absoluteErrors)
xlabel('Absolute Error (cm)')
ylabel('Number of Times Occurred')
title(['Outdoors: Histogram of absolute error'])

%get the error using the mean filter indoors
trainingData=loadWithMeanFilter('../data/lab-1.mat');
trainingData=[trainingData;loadWithMeanFilter('../data/lab-2.mat')];
trainingData=[trainingData;loadWithMeanFilter('../data/lab-3.mat')];
trainingData=[trainingData;loadWithMeanFilter('../data/lab-4.mat')];
testingData=loadWithMeanFilter('../data/lab-5.mat');

n=16;
defaultCoeffs = [-0.5*ones(2*n,1); zeros(2*n,1)];
meanFilterCoeffs = estimateCalibCoefficients(trainingData,defaultCoeffs);
figure
[avgError, percentErrors, absoluteErrors] =calibrateAndPlot(trainingData, meanFilterCoeffs);
disp(' ')
h=get(gca,'title');
t=get(h,'string');
title([' Indoors: Density Plot of Distance Estimates: ' t])
disp('Mean Filter Indoors: ')
disp(['  average percent error: ' num2str(mean(100*percentErrors)) '%'])
disp(['  average absolute error: ' num2str(mean(abs(absoluteErrors))) 'cm'])
disp(' ')
figure
subplot(2,1,1)
hist(100*percentErrors)
xlabel('Percent Error (%)')
ylabel('Number of Times Occurred')
title(['Indoors: Histogram of percent error'])
subplot(2,1,2)
hist(absoluteErrors)
xlabel('Absolute Error (cm)')
ylabel('Number of Times Occurred')
title(['Indoors: Histogram of absolute error'])



% %get the error using the median filter outdoors
% testingData=loadWithMedianFilter('../data/outside-2.mat');
% trainingData=loadWithMedianFilter('../data/outside-1.mat');
% trainingData=[trainingData;loadWithMedianFilter('../data/outside-3.mat')];
% trainingData=[trainingData;loadWithMedianFilter('../data/outside-4.mat')];
% trainingData=[trainingData;loadWithMedianFilter('../data/outside-5.mat')];
% 
% meanFilterCoeffs = estimateCalibCoefficients(trainingData,16);
% figure
% %[avgError, percentErrors, absoluteErrors] =calibrateAndPlot(testingData, meanFilterCoeffs);
% [avgError, percentErrors, absoluteErrors] =calibrateAndPlot(testingData, meanFilterCoeffs);
% disp(' ')
% h=get(gca,'title');
% t=get(h,'string');
% title(['Median Filter Outdoors: ' t])
% disp('Median Filter Outdoors: ')
% disp(['  average percent error: ' num2str(mean(percentErrors*100)) '%'])
% disp(['  average absolute error: ' num2str(mean(abs(absoluteErrors))) 'cm'])
% disp(' ')
% 
% %get the error using the median filter indoors
% %store the indoor training and testing data
% testingData=loadWithMedianFilter('../data/lab-2.mat');
% trainingData=loadWithMedianFilter('../data/lab-1.mat');
% % trainingData=[trainingData;loadWithMedianFilter('../data/lab-3.mat')];
% % trainingData=[trainingData;loadWithMedianFilter('../data/lab-4.mat')];
% % trainingData=[trainingData;loadWithMedianFilter('../data/lab-5.mat')];
% 
% meanFilterCoeffs = estimateCalibCoefficients(trainingData,16);
% figure
% %[avgError, percentErrors, absoluteErrors] =calibrateAndPlot(testingData, meanFilterCoeffs);
% [avgError, percentErrors, absoluteErrors] =calibrateAndPlot(trainingData, meanFilterCoeffs);
% disp(' ')
% h=get(gca,'title');
% t=get(h,'string');
% title(['Median Filter Indoors: ' t])
% disp('Median Filter Indoors: ')
% disp(['  average percent error: ' num2str(mean(100*percentErrors)) '%'])
% disp(['  average absolute error: ' num2str(mean(abs(absoluteErrors))) 'cm'])
% disp(' ')
% 
