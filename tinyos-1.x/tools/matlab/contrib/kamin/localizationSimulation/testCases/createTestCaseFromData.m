function t=createTestCaseFromData(rangingData, positions,calibrationCoeffs,whichOne)
%t=createTestCaseFromData(rangingData)
%
%this function takes ranging data and creates a test case from it.

nodeIDs=[];
for i=1:max(max(positions))
    [r,c]=find(positions==i);
    t.xy(i,1:2)=[r c];
    if ~isempty(t.xy(i,1))
        nodeIDs(end+1)=i;
    end
end

t.xy=t.xy*30;
xy = t.xy(:,1)+t.xy(:,2)*1i;
[X,Y]=meshgrid(xy);
t.distanceMatrix=abs(X-Y);
t.connectivityMatrix = ones(size(t.distanceMatrix));
t.kd = rangingData(nodeIDs, nodeIDs, 2);
t.bx = [min(t.xy(:,1)) max(t.xy(:,1)) min(t.xy(:,1)) max(t.xy(:,1))];
t.nodeIDs=nodeIDs;
t.anchorNodes=[positions(1,1) positions(1,4) positions(8,3)];
t.xyEstimate=[];
 
normalizationFactor = max(max(max(max(rangingData))));
rangingData = rangingData./normalizationFactor;
[calibratedDistances, trueDistances, transmitterIDs, receiverIDs, times] = calibrateRangingData(rangingData, calibrationCoeffs);
for i=1:length(calibratedDistances)
    t.kd(transmitterIDs(i), receiverIDs(i)) = calibratedDistances(i)*normalizationFactor;
end

if whichOne==1
    t.connectivityMatrix = t.distanceMatrix<=68;%30*sqrt(2);
    t.kd = t.kd.*t.connectivityMatrix;
    t.nodeIDs(8)=[];
	t.xy=t.xy(t.nodeIDs,:);
	t.distanceMatrix=t.distanceMatrix(t.nodeIDs, t.nodeIDs);
	t.connectivityMatrix=t.connectivityMatrix(t.nodeIDs, t.nodeIDs);
	t.kd=t.kd(t.nodeIDs, t.nodeIDs);
elseif whichOne==2
    t.connectivityMatrix = t.distanceMatrix<=68;%30*sqrt(2);
    t.kd = t.kd.*t.connectivityMatrix;
    t.nodeIDs([21 1 20 3 11 19 2 6 14 12 13 25 24 9 27 8])=[];
	t.xy=t.xy(t.nodeIDs,:);
	t.distanceMatrix=t.distanceMatrix(t.nodeIDs, t.nodeIDs);
	t.connectivityMatrix=t.connectivityMatrix(t.nodeIDs, t.nodeIDs);
	t.kd=t.kd(t.nodeIDs, t.nodeIDs);
else
    t.nodeIDs(8)=[];
	t.xy=t.xy(t.nodeIDs,:);
	t.distanceMatrix=t.distanceMatrix(t.nodeIDs, t.nodeIDs);
	t.connectivityMatrix=t.connectivityMatrix(t.nodeIDs, t.nodeIDs);
	t.kd=t.kd(t.nodeIDs, t.nodeIDs);
end