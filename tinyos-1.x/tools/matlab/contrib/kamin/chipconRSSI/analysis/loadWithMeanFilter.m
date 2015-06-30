function data = loadWithMeanFilter(filename)
%
%this function reads the "data" structure from the file specified.
%
%it should be a structure with fields:
%data.positions =[nodeID xPos yPos zPos] in centimeters
%data.RSSI = [receiverId transmitterId packetNumber packetIndex rssi-1 rssi-2 ... rssi-10] 
%
%this function returns the data in the format:
%data = [receiverId transmitterId estimatedDistance trueDistance]
%where estimated distance is the mean of all rssi readings from transmitter
%to receiver and true distance is calculated from the positions in
%data.positions.

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
            x(row,3)=mean(mean(rssi(:,5:14)));

%             reading=mean(mean(rssi(:,5:14))); %here I tried to actually use the correct equations, but it didn't work
%             dBm=-51.3*3*reading/1024 - 49.2;
%             x(row,3)=2^((-49.2-dBm)/6);
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