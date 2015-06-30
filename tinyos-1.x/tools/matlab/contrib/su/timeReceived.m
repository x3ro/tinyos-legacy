function messageReceived(address, message)

% Before the test, type the following two command in command window to initilize reference.
% global reference
% reference = 0

% global lastTime
% global timeStamps

global moteID
global currentTime
global timeStamp
global reference
global delta
global matlabReference

matlabTime = clock;
% timeStamps(end+1) = message.get_timeL

moteID(end+1) = message.get_source_addr;
currentTime(end+1) = matlabTime(end-1)*60 + matlabTime(end);
 
timeStamp(end+1)= message.get_timeL
if (timeStamp(end)-reference) > 10000;
    reference = timeStamp(end);
%     matlabreference = matlabTime(end-1)*60 + matlabTime(end);
end
if (reference - timeStamp(end)) > 10000;
    reference = timeStamp(end);
end
% currentTime(end+1) = matlabReference;
delta(end+1) = timeStamp(end) - reference
% hold off

plot(currentTime(moteID ==2)-currentTime(1), delta(moteID ==2),'.r')
hold on
plot(currentTime(moteID == 3)-currentTime(1), delta(moteID == 3),'.g')
hold on
plot(currentTime(moteID == 4)-currentTime(1), delta(moteID == 4),'.b')
% a=axis;
% a(1)=a(1)-1;
% a(2)=a(2)+1;
% a(3)=a(3)-1;
% a(4)=a(4)+1;
% axis(a);
