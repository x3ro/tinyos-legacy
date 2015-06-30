cd ..
cd ..
cd data/TOF_GRID-10-12-02
load TOF-GRID-10-12-02
rangingData = convertToF_DISTANCEtoRangingData(TOF);
cd ../..
cd calibrateTof
cd analysis
rangingData = filterRangingData(rangingData);
knowledgeMatrix = generateKnowledgeMatrix(rangingData, .75);
rangingReduced = imposeKnowledgeMatrix(rangingData, knowledgeMatrix);
calibrationCoeffs = generateLsqrCalibrationCoeffs(rangingReduced(:,:,1,:));
