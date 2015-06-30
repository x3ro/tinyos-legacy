function runCommStack
%function runCommStack
%this function goes through all packetPorts
%it gets the data from their dataPorts and parses it for them

global COMM
global START_SYMBOL_BYTES

if isfield(COMM,'packetPorts')
    for i=1:length(COMM.packetPorts)
        dataPort = get(COMM.packetPorts(i),'dataPort');
        bytes=dataPort(1).getPacketBuffer;
        bytes=double(bytes);
        bytes = bytes(strmatch(START_SYMBOL_BYTES,bytes),:);
		if isempty(bytes)  %these three lines are more efficient when using clock driven reads with possibility of no data
            continue
        end
        data2packets(dataPort(1),COMM.packetPorts(i),bytes);
    end
end