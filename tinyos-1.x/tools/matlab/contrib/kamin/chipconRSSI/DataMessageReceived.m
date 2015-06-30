function DataMessageReceived(address, message)

global CHIPCON
CHIPCON.numRSSIMsgsReceived=CHIPCON.numRSSIMsgsReceived+1;
disp(['RSSI data msg received: ' num2str(message.get_msgIndex) ' at ' num2str(message.get_rfPower) ' from ' num2str(message.get_receiverId)])

trans=CHIPCON.RSSI(find(CHIPCON.RSSI(:,2)==message.get_msgNumber ), :);
transrec=trans(find(trans(:,1)==message.get_receiverId), :);
transrecmsg=transrec(find(transrec(:,3)==message.get_msgIndex), :);
transrecmsgpower=transrecmsg(find(transrecmsg(:,4)==CHIPCON.rfPowers(CHIPCON.rfPower)), :);
if isempty(transrecmsgpower)
    CHIPCON.RSSI(CHIPCON.rssiLength,:)=[message.get_receiverId message.get_msgNumber message.get_msgIndex CHIPCON.rfPowers(CHIPCON.rfPower) message.get_rssi'];
    CHIPCON.rssiLength=CHIPCON.rssiLength+1;
end
