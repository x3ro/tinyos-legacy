function initTESTBED(addr)
global TESTBED
if nargin<1 | isempty(addr) addr='all'; end

TESTBED.retry=3;
%TESTBED.anchorNodes=[10 12 16 18];
xy = TESTBED.xy(:,1) +TESTBED.xy(:,2)*1i;
[X1,X2]=meshgrid(xy);
TESTBED.distanceMatrix=round(abs(X1-X2));
TESTBED.bx = [min(0, min(TESTBED.xy(:,1))) max(TESTBED.xy(:,2)) min(0, min(TESTBED.xy(:,1))) max(TESTBED.xy(:,2))];
TESTBED.xyEstimate=TESTBED.xy; 
TESTBED.msgsReceived=0;
TESTBED.readyToChangeState=0;
TESTBED.managementMsgs=[];
TESTBED.corrections={};
TESTBED.rangingReports={};
%TESTBED.runState='idle';
TESTBED.deadNodes=[];

if strcmp(addr,'all')
  for t=length(TESTBED.nodeIDs)
    for r=length(TESTBED.nodeIDs)
      TESTBED.rangingEstimates{t,r}=[]; %ranging estimates are all estimates sent out by diag msgs
      TESTBED.rangingWindow{t,r}=[]; %the ranging window is current state of ranging window
      TESTBED.rangingValuesReportedMask{t,r}=[]; %whether or not estimates were reported yet
    end
  end
  TESTBED.rangingReceived=zeros(1,length(TESTBED.nodeIDs));
  TESTBED.chirpSent=zeros(1,length(TESTBED.nodeIDs));
  TESTBED.identReported=zeros(1,length(TESTBED.nodeIDs));
  TESTBED.serviceReported=zeros(1,length(TESTBED.nodeIDs));
  TESTBED.anchorsReported=zeros(1,length(TESTBED.nodeIDs));
  TESTBED.rangingReported=zeros(1,length(TESTBED.nodeIDs));
  TESTBED.rangingValuesReported=zeros(1,length(TESTBED.nodeIDs));
  TESTBED.locationReported=zeros(1,length(TESTBED.nodeIDs));
  TESTBED.connectivityMatrix=zeros(size(TESTBED.distanceMatrix));
  TESTBED.shortestPathConnectivityMatrix=zeros(size(TESTBED.distanceMatrix));
  TESTBED.nextConnectivityMatrix=zeros(size(TESTBED.distanceMatrix));
  TESTBED.kd=-ones(size(TESTBED.distanceMatrix));
  TESTBED.shortestPath=-ones(size(TESTBED.distanceMatrix));
else
  index=find(TESTBED.nodeIDs==addr);
  TESTBED.rangingReceived(index)=0;
  TESTBED.chirpSent(index)=0;
  TESTBED.identReported(index)=0;
  TESTBED.anchorsReported(index)=0;
  TESTBED.rangingReported(index)=0;
  TESTBED.locationReported(index)=0;
  TESTBED.connectivityMatrix(index,:)=zeros(1,size(TESTBED.distanceMatrix,2));
  TESTBED.connectivityMatrix(:,index)=zeros(size(TESTBED.distanceMatrix,1),1);
  TESTBED.shortestPathConnectivityMatrix(index,:)=zeros(1,size(TESTBED.distanceMatrix,2));
  TESTBED.nextConnectivityMatrix(:,index)=zeros(size(TESTBED.distanceMatrix,1),1);
  TESTBED.kd(index,:)=-ones(1,size(TESTBED.distanceMatrix,2));
  TESTBED.shortestPath(:,index)=-ones(size(TESTBED.distanceMatrix,1),1);
end


