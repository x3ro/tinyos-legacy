load TOF-GRID-10-12-02
rangingData = convertToF_DISTANCEtoRangingData(TOF);
rangingData = filterRangingData(rangingData);
defaultCoeffs = repmat([.5; 0],2*size(rangingData,1));
plotRangingData(rangingData(:,:,4:5,:), defaultCoeffs);

% calibrationCoeffs = generateLsqrCalibrationCoeffs(rangingData(:,:,1:3,:));
% %calibrationCoeffs = generateNaiveCalibrationCoeffs(rangingData(:,:,1:3,:));
% figure
% plotRangingData(rangingData(:,:,4:5,:), calibrationCoeffs);
% 
% for i=1:3
% 	knowledgeMatrix{i} = generateKnowledgeMatrix(rangingData, 1-(.25*i));
% 	rangingReduced = imposeKnowledgeMatrix(rangingData, knowledgeMatrix{i});
% 	reducedCoeffs{i} = generateLsqrCalibrationCoeffs(rangingReduced(:,:,1:3,:));
% %	reducedCoeffs{i} = generateNaiveCalibrationCoeffs(rangingReduced(:,:,1:3,:));
%     figure
%     plotRangingData(rangingData(:,:,4:5,:), reducedCoeffs{i})
% end
% 
% i=4;
% knowledgeMatrix{i} = generateKnowledgeMatrix(rangingData, .1);
% rangingReduced = imposeKnowledgeMatrix(rangingData, knowledgeMatrix{i});
% reducedCoeffs{i} = generateLsqrCalibrationCoeffs(rangingReduced(:,:,1:3,:));
% %reducedCoeffs{i} = generateNaiveCalibrationCoeffs(rangingReduced(:,:,1:3,:));
% figure
% plotRangingData(rangingData(:,:,4:5,:), reducedCoeffs{i})
% 
% i=5;
% knowledgeMatrix{i} = generateKnowledgeMatrix(rangingData, 0);
% rangingReduced = imposeKnowledgeMatrix(rangingData, knowledgeMatrix{i});
% reducedCoeffs{i} = generateLsqrCalibrationCoeffs(rangingReduced(:,:,1:3,:));
% %reducedCoeffs{i} = generateNaiveCalibrationCoeffs(rangingReduced(:,:,1:3,:));
