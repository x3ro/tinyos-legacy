function magPlotReceivePackets(s, packet)
%pursuerEvaderReceivePackets(s, packet)
%
%This function is called whenever a packet is received
%It assumes that all NETWORK_MOTE_IDS are in known positions and that
%the pursuer will be localized given TOF measurements and that the 
%evader will be localized given magnetometer measurements.
%resetTOFcalibration(transmitterIDs, receiverIDs)


global mag_data_array
global MAG_DISPLAY_PLOT
global count
mag = get(packet,'mag');
mag = mag.^.5;
mag_data_array = [mag_data_array, mag];
mag_data_array = [mag_data_array, mag];
start = length(mag_data_array) - 600;
if start < 1 
	start = 1;
end;

foo = 1;
mag_data_array = mag_data_array(start:end);

ff = ones(1,5) / 5;
mda_ff = filter( ff, 1, mag_data_array );


set(MAG_DISPLAY_PLOT, 'YData', mda_ff);
set(MAG_DISPLAY_PLOT, 'XData', 1:length(mda_ff));
