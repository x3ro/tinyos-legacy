function localizationReceivePackets(s, packet)
%localizationReceivePackets(s, packet)
%
%This function recieves new packets from the motes we are trying to localize.
%And processes them

global LOCALIZATION
global TOF_CALIBRATION

global TOF_RANGING_CALIBRATION
global TOF_RANGING_RANGING
global TOF_RANGING_CHIRP_AM_HANDLER
global TOF_RANGING_DATA_AM_HANDLER

%check the AM handler and print something to the user about progress
AM=get(packet,'AM');
% if AM==TOF_RANGING_CHIRP_AM_HANDLER & get(packet,'context')==TOF_RANGING_CALIBRATION
%     transmitterID = get(packet, 'srcID');
%     disp([ num2str(transmitterID) ' chirped'])
%     return
% elseif AM==TOF_RANGING_DATA_AM_HANDLER
if AM==TOF_RANGING_DATA_AM_HANDLER
    receiverID = get(packet, 'srcID');
	transmitterID = get(packet, 'transmitterID');
	if sum(receiverID == LOCALIZATION.moteIDs)==0 |  sum(transmitterID == LOCALIZATION.moteIDs)==0  
        return
	end
%	disp([num2str(transmitterID) ' measured ' num2str(receiverID) ' at ' num2str(get(packet, 'distance')) 'cm'])
else
    return
end

if get(packet,'distance')<150 & get(packet,'distance')>0
    LOCALIZATION.distances(transmitterID, receiverID)=calibrateReading(get(packet,'distance'),transmitterID, receiverID);
end

%now, check if we are done with this guy
if now-LOCALIZATION.timeStarted > LOCALIZATION.timeDuration
    removePacketListeners(getPortMapping(LOCALIZATION.moteIDs), 'tofCalibrationReceivePackets');
    routePackets(LOCALIZATION.activeTransmitter, tofChirpCommand(0, LOCALIZATION.activeTransmitter, TOF_RANGING_CALIBRATION));
    routePackets(LOCALIZATION.activeTransmitter, tofChirpCommand(0, LOCALIZATION.activeTransmitter, TOF_RANGING_CALIBRATION));
    routePackets(LOCALIZATION.activeTransmitter, tofChirpCommand(0, LOCALIZATION.activeTransmitter, TOF_RANGING_CALIBRATION));
    disp(['Localizationcompleted for mote: ' num2str(LOCALIZATION.activeTransmitter)])

    localizationRefresh([transmitterID, receiverID]);
    
    startLocalization;
    return
end
