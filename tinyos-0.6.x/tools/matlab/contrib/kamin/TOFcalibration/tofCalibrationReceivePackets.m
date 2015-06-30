function tofCalibrationReceivePackets(s, packet)
%tofCalibrationReceivePackets(s, packet)
%
%This function is called whenever a packet is received

global TOF_CALIBRATION

global TOF_RANGING_CALIBRATION
global TOF_RANGING_RANGING
global TOF_RANGING_CHIRP_AM_HANDLER
global TOF_RANGING_DATA_AM_HANDLER

%check if we are done with this transmitter and, if we are, see if there is another one to calibrate
if now-TOF_CALIBRATION.timeStarted > TOF_CALIBRATION.timeDuration
    removePacketListeners(getPortMapping(TOF_CALIBRATION.receiverIDs), 'tofCalibrationReceivePackets');
    routePackets(TOF_CALIBRATION.activeTransmitter, tofChirpCommand(0, TOF_CALIBRATION.activeTransmitter, TOF_RANGING_CALIBRATION));
    routePackets(TOF_CALIBRATION.activeTransmitter, tofChirpCommand(0, TOF_CALIBRATION.activeTransmitter, TOF_RANGING_CALIBRATION));
    routePackets(TOF_CALIBRATION.activeTransmitter, tofChirpCommand(0, TOF_CALIBRATION.activeTransmitter, TOF_RANGING_CALIBRATION));
    disp(['TOF calibration completed for mote: ' num2str(TOF_CALIBRATION.activeTransmitter)])

    %save the data
    save TOF_CALIBRATION
    
    %now restart the whole process
    if TOF_CALIBRATION.interactive==1
        oldActiveTransmitter=TOF_CALIBRATION.activeTransmitter;
        TOF_CALIBRATION.activeTransmitter=[];
        for i=1:length(TOF_CALIBRATION.transmitterIDs)
            if TOF_CALIBRATION.transmitterIDs(i)>oldActiveTransmitter
                TOF_CALIBRATION.activeTransmitter=TOF_CALIBRATION.transmitterIDs(i);  
                break
            end
        end
    end
    
    startTOFcalibration;
    return
end

%otherwise, process the data
%check the AM handler and print something to the user about progress
AM=get(packet,'AM');
if AM==TOF_RANGING_CHIRP_AM_HANDLER & get(packet,'context')==TOF_RANGING_CALIBRATION
    transmitterID = get(packet, 'srcID');
    disp([ num2str(transmitterID) ' chirped'])
    return
elseif AM==TOF_RANGING_DATA_AM_HANDLER
    receiverID = get(packet, 'srcID');
	transmitterID = get(packet, 'transmitterID');
	if sum(receiverID == TOF_CALIBRATION.receiverIDs)==0 |  sum(transmitterID == TOF_CALIBRATION.transmitterIDs)==0  
        return
	end
	disp([num2str(transmitterID) ' measured ' num2str(receiverID) ' at ' num2str(get(packet, 'distance')) 'cm'])
else
    return
end

%store the reading that we got if it is reasonable
if get(packet, 'distance')<150 & get(packet, 'distance')>0
	TOF_CALIBRATION.readings{transmitterID, receiverID}(1,end+1) = get(packet, 'distance');
	
	%and store the true distance with it
	[xT yT] = getLocation(transmitterID);
	[xR yR] = getLocation(receiverID);
	TOF_CALIBRATION.readings{transmitterID, receiverID}(2,end) = sqrt( (xT-xR)^2 + (yT-yR)^2 );
	
	%now add these two readings to the plot
	x=[get(TOF_CALIBRATION.plotHandle, 'XData') TOF_CALIBRATION.readings{transmitterID, receiverID}(2,end)];
	y=[get(TOF_CALIBRATION.plotHandle, 'YData') TOF_CALIBRATION.readings{transmitterID, receiverID}(1,end)];
	set(TOF_CALIBRATION.plotHandle, 'XData', x, 'YData', y)
end


