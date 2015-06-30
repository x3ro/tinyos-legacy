function resetTOFcalibration(varargin)
%resetTOFcalibration(transmitterIDs, receiverIDs)
%
%This function will erase all the data and calibration coefficients for the nodes
%that are passed as parameters.  IF none are specified, it resets all of them

global TOF_CALIBRATION

%only reset the nodes passed as parameters, unless none were passed
if length(varargin)>1
    transmitterIDs = varargin{1};
else
    transmitterIDs=TOF_CALIBRATION.transmitterIDs;
end

if length(varargin)>0
    receiverIDs = varargin{1};
else
    receiverIDs=TOF_CALIBRATION.receiverIDs;
end


%initialize all the cell arrays so that they exist
if ~isfield(TOF_CALIBRATION, 'readings')
    TOF_CALIBRATION.readings={};
end
for i=1:length(transmitterIDs)
    for j=1:length(receiverIDs)
        TOF_CALIBRATION.readings{transmitterIDs(i),receiverIDs(j)}=[];
    end
end

for i=1:length(transmitterIDs)
    TOF_CALIBRATION.transmitterCoefficients{i}=[];
end
for j=1:length(receiverIDs)
    TOF_CALIBRATION.receiverCoefficients{j}=[];
end

