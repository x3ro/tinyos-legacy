function watchFreqReceiveNewData(packetPort, packet, h)
%watchFreqReceiveNewData(packetPort, packet, h)
%
%This function is called by the packetPort event handler.
%It is passed the handle of the WATCH figure to plot to, and is given the received packet
%
%The data is extracted from the packet and added to the figure.
%The way to add it to the figure is stored in the figure itself

%disp('entered watchreceivenewData')
watchParams = get(h,'UserData');
data = get(packet, watchParams.fieldName);
moteID = get(packet, 'moteID');
if ~isempty(watchParams.filterName)
    filter = watchParams.filterName;
    eval(['data = ' filter '(moteID, data);']);
end
watchParams.history = [watchParams.history data];
watchParams.history = timeWindow(watchParams.history, watchParams.timeWindow);
set(h,'UserData', watchParams);           
addMethod = watchParams.addMethod;
eval([addMethod '(h, watchParams.history);']);
%disp('left watchreceivenewData')
