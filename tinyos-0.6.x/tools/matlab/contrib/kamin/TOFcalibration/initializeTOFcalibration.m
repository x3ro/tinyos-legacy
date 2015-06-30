function tof_calibration=initializeTOFcalibration(transmitterIDs, receiverIDs, varargin)
%tof_calibration=initializeTOFcalibration(transmitters, receivers, interactive, timeDuration)
%
%This function will initialize TOF_CALIBRATION for the motes that you are using.
%it will not erase any information that you previously used, it just ensures that
%you will not get 'out of bounds' errors

    

global TOF_CALIBRATION

TOF_CALIBRATION.transmitterIDs = sort(transmitterIDs);
TOF_CALIBRATION.receiverIDs = sort(receiverIDs);


%initialize all the cell arrays so that they exist
if ~isfield(TOF_CALIBRATION, 'readings')
    TOF_CALIBRATION.readings={};
end
[r c] = size(TOF_CALIBRATION.readings);
if r<max(transmitterIDs) | c<max(receiverIDs)
    TOF_CALIBRATION.readings{max(transmitterIDs), max(receiverIDs)}=[];
end

if ~isfield(TOF_CALIBRATION, 'transmitterCoefficients')
    TOF_CALIBRATION.transmitterCoefficients={};
end
if ~isfield(TOF_CALIBRATION, 'receiverCoefficients')
    TOF_CALIBRATION.receiverCoefficients={};
end


%parse the "interactive" parameter:
if length(varargin)>0
    TOF_CALIBRATION.interactive=varargin{1};
    TOF_CALIBRATION.activeTransmitter=TOF_CALIBRATION.transmitterIDs(1);
else
    TOF_CALIBRATION.interactive=0;
end

%parse the "timeDuration" parameter:
if length(varargin)>1
    TOF_CALIBRATION.timeDuration=varargin{2};
else
    TOF_CALIBRATION.timeDuration=.0001;%about 10 seconds
end