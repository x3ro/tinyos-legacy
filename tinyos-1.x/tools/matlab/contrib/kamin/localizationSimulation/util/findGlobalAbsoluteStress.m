function [globalStress,stressMatrix,currentDistances]=findGlobalAbsoluteStress(xy,trueDistances, varargin)
%[stress,stressMatrix,currentDistances]=findGlobalAbsoluteStress(xy,trueDistances,<validDistances>)
%
%This function takes the current XY positions, the true distances and a set
%of valid distances.
%
%It returns the globalStress (in terms of absolute devation between
%currentDistances and true distances), the stress of each distance and the
%value of each current distance

if nargin==1 
    validDistances=varargin{1}
else 
    validDistances=(trueDistances-eye(length(xy)))>=0;
    validDistances = double(validDistances);
end

validDistancesIndices=find(validDistances);
stressMatrix=validDistances;
currentDistances=validDistances;
[X1,X2]=meshgrid(xy); 
currentDistances(validDistancesIndices)=X1(validDistancesIndices)-X2(validDistancesIndices);
stressMatrix(validDistancesIndices) = abs(currentDistances(validDistancesIndices))-trueDistances(validDistancesIndices);
%globalStress = sum(abs(stressMatrix(validDistancesIndices)))/(sum(trueDistances(:)>=0)-length(trueDistances));
globalStress = sum(abs(stressMatrix(validDistancesIndices)));
% size(StstressMatrix = reshape(stressMatrix, size(trueDistances,1), size(trueDistances, 2));
% currentDistances = reshape(currentDistances, size(trueDistances,1), size(trueDistances, 2));