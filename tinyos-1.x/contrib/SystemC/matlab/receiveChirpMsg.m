    function receiveChirpMsg(text, flag)
%this function timestamps the chirp messages as they come in

if nargin<2
    global MONITOR_DATA
    MONITOR_DATA.globalTimestamp(text.addr, text.seqNo)=rem(now,1);
else
    %this part was added for the collisionTest application
    global COLLISION
    string=text.STRING(19:end);
    temp = strfind(string,' ');
    transmitter=str2num(string(2:temp(2)));
    string=string(temp(2):end);
    temp = strfind(string,' ');
    receiver=str2num(string(2:temp(2)));
    string=string(temp(2):end);
    distance=str2num(string(2:end));
    COLLISION.rangingData(length(COLLISION.distances),receiver, transmitter,end+1)=distance;
end
    