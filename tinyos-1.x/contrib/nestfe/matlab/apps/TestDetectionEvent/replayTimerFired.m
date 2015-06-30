function replayTimerFired
% Helper function for replaying log.  Do not call this function directly.

global TESTDETECT;
global replayMat;
global replayIndex;
global replayTimer;
global replayTimerToggle;
global replayTime;
detectMsg = net.tinyos.drain_msgs.DetectionEvent.DetectionEventMsg;

firstIndex = replayIndex;
nextTime = 0;
% replay all packets within 0.1 seconds of last timer firing
while ((nextTime < 0.1) && (replayIndex <= size(replayMat,2)))
    detectMsg.set_type(40);
    detectMsg.set_source(replayMat(1,replayIndex)); %moteID
    detectMsg.set___nesc_keyword_event_time(replayMat(7,replayIndex)); %detectTime
    detectMsg.set___nesc_keyword_event_location_x(replayMat(3,replayIndex)); %xPos
    detectMsg.set___nesc_keyword_event_location_y(replayMat(4,replayIndex)); %yPos
    detectMsg.set___nesc_keyword_event_strength(replayMat(5,replayIndex)); %strength
    detectMsg.set___nesc_keyword_event_type(...
        net.tinyos.drain_msgs.DetectionEvent.DetectionEventConst.PIR_FILTER); %detectType
    
    detectionEventMsgReceived(0,detectMsg);
    replayIndex = replayIndex+1;
    if (replayIndex <= size(replayMat,2))
        nextTime = replayMat(7,replayIndex) - replayMat(7,firstIndex);
        nextTime = nextTime/65536;
    end
end
drawnow;

modTime = mod(replayTime,TESTDETECT.decayPeriod);
if (modTime + nextTime > TESTDETECT.decayPeriod) 
    decayTimerFired;
    drawnow;
end
replayTime = replayTime + nextTime;

% restart timer;
replayTimerToggle = mod(replayTimerToggle,2) + 1;
if (replayIndex <= size(replayMat,2))
    set(replayTimer{replayTimerToggle},'Period',round(10*nextTime)/10 + 0.01); %0.1 second increments
    start(replayTimer{replayTimerToggle});
end