function rangingData = imposeKnowledgeMatrix(rangingData, knowledgeMatrix)
%rangingData = imposeKnowledgeMatrix(rangingData, knowledgeMatrix)
%
%This function imposes a knowledge matrix on the known distances in the
%rangingData matrix.   If the distance is unknown, the known distance in
%the rangingData should be -1, and this function artificially enforces
%that.

for transmitter = 1:size(rangingData,1)
    for receiver = 1:size(rangingData,2)
        for time = 1:size(rangingData,3) %assume TOF is a vector of TOF_DISTANCE structures
            if knowledgeMatrix(transmitter, receiver, time) < 1
                rangingData(transmitter, receiver, time, 1) = -1;
            end
        end
    end  
end   
