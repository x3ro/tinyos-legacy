function receiveMonitorData(text)
%this function takes the parsed data message structure and stores it in a big structure

global MONITOR_DATA
global NUM_STRAYS
global NUM_SAMPLES


MONITOR_DATA.rxArray(text.addr, text.currentIndex)=1;

if(text.ID==0) return; end;

switch(text.requestType)
case 1 %ranging data
MONITOR_DATA.rangingData(text.addr, text.ID,:)= text.samples;
case 2 %timestampH followed by seqNo
MONITOR_DATA.timestampH(text.addr, text.ID,:)= text.samples(1:end/2);
MONITOR_DATA.seqNo(text.addr, text.ID,:)= text.samples(end/2+1:end);
case 3 %timestampL
MONITOR_DATA.timestampL(text.addr, text.ID,:)= text.samples;
case 4 %strays rangingData
MONITOR_DATA.strayRangingData(text.addr, text.ID,:)= text.samples;
case 5 %strays timestampH
MONITOR_DATA.strayTimestampH(text.addr, text.ID,:)= text.samples;
MONITOR_DATA.strayTimestamp(text.addr, text.ID,:)=MONITOR_DATA.strayTimestampH(text.addr, text.ID,:).*65536.+MONITOR_DATA.strayTimestampL(text.addr, text.ID,:);
case 6 %strays timestampL
MONITOR_DATA.strayTimestampL(text.addr, text.ID,:)= text.samples;
MONITOR_DATA.timestamp(text.addr, text.ID,:)=MONITOR_DATA.strayTimestampH(text.addr, text.ID,:).*65536.+MONITOR_DATA.strayTimestampL(text.addr, text.ID,:);
end

%if isfield(MONITOR_DATA, 'timestampL') & isfield(MONITOR_DATA, 'timestampH')
%   MONITOR_DATA.timestamp(text.addr, text.ID,:)=MONITOR_DATA.timestampH(text.addr, text.ID,:).*65536.+MONITOR_DATA.timestampL(text.addr, text.ID,:);
%end
