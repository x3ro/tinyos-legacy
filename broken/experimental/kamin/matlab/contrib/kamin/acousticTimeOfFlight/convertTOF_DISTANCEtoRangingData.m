function rangingData = convertTOF_DISTANCEtoRangingData(TOF)
%rangingData = convertTOF_DISTANCEtoRangingData(Tof)
%This function takes the old format that I was using to store TOF data
%and converts it to the new format: rangingData.  The new format is:
%
%rangingData(transmitter, receiver, time, [truth estimate], sample)
%
%i.e. the first dimension indexes the transmitter, the third the time
%instance, etc.  the last dimension only has two values: 1 for true
%distance and 2 for estimated distance.

rangingData=[];

for time = 1:length(TOF) %assume TOF is a vector of TOF_DISTANCE structures
    tof = TOF(time);
    for transmitter = 1:size(tof.readings,1)
        for receiver = 1:size(tof.readings,2)
            if ~isempty(tof.readings{transmitter, receiver})
                rangingData(transmitter, receiver, time, 1:2, 1:size(tof.readings{transmitter, receiver},1)) = tof.readings{transmitter, receiver}';
            end
        end
    end
end
    