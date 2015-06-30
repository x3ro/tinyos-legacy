function rangingData = convertTOF_DISTANCEtoRangingDataArray(TOF)
%rangingData = convertTOF_DISTANCEtoRangingDataArray(Tof)
%This function takes the old format that I was using to store TOF data
%and converts it to the new format: rangingData.  The new format is:
%
%rangingData(transmitter, receiver, time, sample, [truth estimate])
%
%i.e. the first dimension indexes the transmitter, the third the time
%instance, etc.  the last dimension only has two values: 1 for true
%distance and 2 for estimated distance.

rangingData=[];

for time = 1:length(TOF) %assume TOF is a vector of TOF_DISTANCE structures
    tof = TOF(time);
    for transmitter = 1:size(tof.readings,1)
        for receiver = 1:size(tof.readings,2)
            rangingData = [rangingData; [transmitter receiver time tof.readings{transmitter, receiver}]];
        end
    end
end

rangingData = rangingData(logical(rangingData(:,4)~=0 & rangingData(:,5)~=0));