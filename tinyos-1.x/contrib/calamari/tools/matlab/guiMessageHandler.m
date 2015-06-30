function  guiMessageHandler(varargin)
feval(varargin{:});


function ident(text)
global TESTBED;
TESTBED.identReported(TESTBED.nodeIDs==text.routing_origin)=1;

function service(text)
global TESTBED;
if text.RunningService==50
  TESTBED.serviceReported(TESTBED.nodeIDs==text.routing_origin)=1;
end

function chirpSent(text)
global TESTBED;
TESTBED.chirpSent(TESTBED.nodeIDs==text.transmitterID)=1;
if text.sequenceNumber==TESTBED.numChirps & strcmpi(TESTBED.runState, 'calamariRanging')
  TESTBED.msgsReceived=0; 
  TESTBED.readyToChangeState=100; 
  runlocalization
end

function correction(text)
global TESTBED;
t.src=text.src;
t.numCorrections=text.numCorrections;
t.sourceAnchor=text.sourceAnchor;
t.correctedAnchor=text.correctedAnchor;
t.correction=text.correction;
TESTBED.corrections{end+1}=t;
% $$$ TESTBED.chirpSent(TESTBED.nodeIDs==text.transmitterID)=1;
% $$$ if text.sequenceNumber==TESTBED.numChirps & strcmpi(TESTBED.runState, 'calamariRanging')
% $$$   TESTBED.msgsReceived=0; 
% $$$   TESTBED.readyToChangeState=100; 
% $$$   runlocalization
% $$$ end



function managementMsg(text)
global TESTBED;
if isfield(text,'addr')
  TESTBED.managementMsgs(end+1,:)=[text.routing_origin text.addr text.hopCount now];
end

function anchorReport(text)
global TESTBED;
index=find(TESTBED.nodeIDs==text.addr);
TESTBED.anchorsReported(index)=1;
num_neighbors = text.numberOfAnchors;
for i = 1:num_neighbors;
  index2=find(TESTBED.nodeIDs==text.anchors.addr(i));
  index3=find(TESTBED.nodeIDs==text.anchors.next(i));
  TESTBED.shortestpath(index,index2)=text.anchors.dist(i);
  TESTBED.hopCount(index,index2)=text.anchors.hopCount(i);
  TESTBED.shortestPathConnectivityMatrix(index,index2)=1;
  TESTBED.nextConnectivityMatrix(index,index3)=1;
end


function rangingReport(text)
global TESTBED;
index=find(TESTBED.nodeIDs==text.addr);
TESTBED.rangingReported(index)=1;
num_neighbors = text.numberOfNeighbors;
for i=1:8
    m.neighbors.dist(9-i)=text.neighbors.dist(9-i);    
    m.neighbors.addr(9-i)=text.neighbors.addr(9-i);
end
m.numberOfNeighbors=text.numberOfNeighbors;
m.addr=text.addr;
TESTBED.rangingReports{end+1}=m;
for i = 1:num_neighbors;
  index2=find(TESTBED.nodeIDs==text.neighbors.addr(i));
  TESTBED.kd(index,index2)=text.neighbors.dist(i);
  if TESTBED.kd(index,index2)>0
    TESTBED.connectivityMatrix(index,index2)=1;
  end
end

function rangingReportValues(text)
global TESTBED;
index=find(TESTBED.nodeIDs==text.addr);
index2=find(TESTBED.nodeIDs==text.actuator);
if index2~=0
  if length(TESTBED.rangingValuesReportedMask{index,index2}) < text.windowSize
    TESTBED.rangingValuesReportedMask{index, index2}(text.windowSize)=0;
  end
  TESTBED.rangingValuesReportedMask{index, index2}(text.firstIndex+1:text.firstIndex+text.numberOfValues)=ones(1,text.numberOfValues);
  TESTBED.rangingWindow{index, index2}(text.firstIndex+1:text.firstIndex+text.numberOfValues)=text.values(1:text.numberOfValues);
end
neighbors=find(TESTBED.connectivityMatrix(index,:));
done=1;
for n=neighbors
  if any(TESTBED.rangingValuesReportedMask{index,n}==0)
    done=0;
  end
end
if done==1
  TESTBED.rangingValuesReported(index)=1;
end


function locationInfo(text)
global TESTBED;
index=find(TESTBED.nodeIDs==text.routing_origin);
if ~isempty(index)
  TESTBED.locationReported(index)=1;
  %convert to signed integers:
  if text.LocationInfo_localizedLocation_x>=32768 & text.LocationInfo_localizedLocation_x<65535
    text.LocationInfo_localizedLocation_x=text.LocationInfo_localizedLocation_x-65536;
  end
  if text.LocationInfo_localizedLocation_y>=32768 & text.LocationInfo_localizedLocation_y<65535
    text.LocationInfo_localizedLocation_y=text.LocationInfo_localizedLocation_y-65536;
  end
  
  TESTBED.xyEstimate(index,:)=[text.LocationInfo_localizedLocation_x text.LocationInfo_localizedLocation_y];
end

function rangingReceived(text)
global TESTBED;
spaces= find(text.STRING==' ');
distance = str2num(text.STRING(spaces(end)+1:end));
receiver = str2num(text.STRING(spaces(end-1)+1:spaces(end)-1));
transmitter = str2num(text.STRING(spaces(end-2)+1:spaces(end-1)-1));
TESTBED.rangingReceived(receiver)=1;
TESTBED.rangingEstimates{transmitter, receiver}=[TESTBED.rangingEstimates{transmitter, receiver} distance];

