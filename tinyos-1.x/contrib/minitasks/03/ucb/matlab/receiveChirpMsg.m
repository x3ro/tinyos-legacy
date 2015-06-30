function receiveChirpMsg(text)
%this function timestamps the chirp messages as they come in

global MONITOR_DATA

MONITOR_DATA.globalTimestamp(text.addr, text.seqNo)=rem(now,1);