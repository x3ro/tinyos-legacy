function data = loadWithMedianFilter(filename)
%
%this function reads the "data" structure from the file specified.
%
%it should be a structure with fields:
%data.positions =[nodeID xPos yPos zPos] in centimeters
%data.RSSI = [receiverId transmitterId packetNumber packetIndex rssi-1 rssi-2 ... rssi-10] 
%
%this function returns the data in the format:
%data = [receiverId transmitterId estimatedDistance trueDistance]
%where estimated distance is the mean of the medians over all packets from
%transmitterId to receiverId, where the median is
%take over all readings for each packet.  If there is an even number of
%readings per packet, it uses an average of the middle two elements.


load(filename)
if length(data.RSSI)==0 error(['no RSSI data in file:' filename]); return; end
    
%this is a hack because the first row of data.RSSI is always zeros:
data.RSSI=data.RSSI(2:end,:);

%first, figure out who the transmitters and receivers are
transmitters=sort(data.RSSI(:,2));
uniques=[find(diff(transmitters)>0); length(transmitters)];
transmitters=transmitters(uniques)';
receivers=sort(data.RSSI(:,1));
uniques=[find(diff(receivers)>0); length(receivers)];
receivers=receivers(uniques)';

%now, for each transmitter/receiver pair
row=1;
for r=receivers
    for t=transmitters
        %store the estimated distance (using the mean filter)
        rssi=data.RSSI(find(data.RSSI(:,2)==t), :);
        rssi=rssi(find(rssi(:,1)==r), :);
        if ~isempty(rssi)
            x(row,3)=mean(median(rssi(:,5:14),2)); 
        else 
            continue;
        end
        
        %store their IDs
        x(row,1:2)=[r t]; 
        
        %store the true distance 
        rPos=data.positions(find(data.positions(:,1)==r),2:3);
        tPos=data.positions(find(data.positions(:,1)==t),2:3);
        x(row,4)=sqrt( (rPos(1)-tPos(1))^2 + (rPos(2)-tPos(2))^2 );
        
        %get ready for the next one
        row=row+1;
    end
end
data=x;