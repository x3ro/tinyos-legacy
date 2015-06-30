function t = boundingBox(t)
%t = boundingBox(t)
%
%This function finds the shortest path from each node to all of the anchor
%nodes.  It uses these path lengths, along with the x,y coords of the
%anchors to generate a bounding box for each node location
%if there are no xyEstimates or a particular xyEstimate falls outside the
%bounding box, this algorithm uses the center of the bounding box as the
%new xyEstimate
shortestPaths = -ones(size(t.kd));

%find the shortest paths
for i=t.anchorNodes
    anchor = (t.nodeIDs==i);
    [dummy, newNodeOrder] = sort(-anchor);
    tempkd = t.kd(newNodeOrder, newNodeOrder);
    tempkd(tempkd==-1) = zeros(1,sum(sum(logical(tempkd==-1))));
    sp = dijkstra(tempkd);
    sp(sp==0)=-1;
    shortestPaths(anchor, newNodeOrder(2:end)) = sp(:,2)';    
    shortestPaths(newNodeOrder(2:end), anchor) = sp(:,2);
end

%calculate a correction factor
anchorIndices = vectorFind(t.anchorNodes, t.nodeIDs);
xy = t.xy(anchorIndices,1)+t.xy(anchorIndices,2)*1i;
[X,Y] = meshgrid(xy);
anchorDists = abs(X-Y);
measuredDists = shortestPaths(anchorIndices, anchorIndices);
scalingFactor = mean(median(anchorDists./measuredDists));
shortestPaths = shortestPaths*scalingFactor;

%generate a bounding box for each node
boundingBox = [-1/0 1/0 -1/0 1/0];
boundingBox = boundingBox(ones(length(t.nodeIDs),1), :); %[xmin xmax ymin ymax]
mobileNodes = find(vectorFind(setdiff(t.nodeIDs, t.anchorNodes), t.nodeIDs));
anchorNodes = find(vectorFind(t.anchorNodes, t.nodeIDs));
for i=mobileNodes'
    for j=anchorNodes'
        if shortestPaths(i,j)>0
            boundingBox(i,1) = max(boundingBox(i,1), t.xy(j,1) - shortestPaths(i,j));
            boundingBox(i,2) = min(boundingBox(i,2), t.xy(j,1) + shortestPaths(i,j));
            boundingBox(i,3) = max(boundingBox(i,3), t.xy(j,2) - shortestPaths(i,j));
            boundingBox(i,4) = min(boundingBox(i,4), t.xy(j,2) + shortestPaths(i,j));
        end
    end
end

%take the estimated position to be the center of the box if there are no
%initial estimates or if some estimates violate the box bounds move them
%until they are within the box
if isempty(t.xyEstimate)
    t.xyEstimate = [mean(boundingBox(:,1:2),2) mean(boundingBox(:,3:4),2)];
else
     t.xyEstimate(:,1) = max(t.xyEstimate(:,1), min(boundingBox(:,1:2),[],2));
     t.xyEstimate(:,1) = min(t.xyEstimate(:,1), max(boundingBox(:,1:2),[],2));
     t.xyEstimate(:,2) = max(t.xyEstimate(:,2), min(boundingBox(:,3:4),[],2));
     t.xyEstimate(:,2) = min(t.xyEstimate(:,2), max(boundingBox(:,3:4),[],2));
%      t.xyEstimate(:,1) = max(t.xyEstimate(:,1), min(boundingBox(:,1),[],2));
%      t.xyEstimate(:,1) = min(t.xyEstimate(:,1), max(boundingBox(:,2),[],2));
%      t.xyEstimate(:,2) = max(t.xyEstimate(:,2), min(boundingBox(:,3),[],2));
%      t.xyEstimate(:,2) = min(t.xyEstimate(:,2), max(boundingBox(:,4),[],2));

end
t.xyEstimate(anchorNodes,:) = t.xy(anchorNodes,:);
