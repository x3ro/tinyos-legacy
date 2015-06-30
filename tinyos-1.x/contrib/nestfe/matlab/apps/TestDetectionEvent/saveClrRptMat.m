function saveClrRptMat(fileName)
% saveClrRptMat(fileName)
%
% automatically saves MTT.reportMat to a file and clears it
global MTT;
global gvs;

dataStructure = MTT.reportMat;
save(fileName,'dataStructure','gvs');
MTT.reportMat = [];