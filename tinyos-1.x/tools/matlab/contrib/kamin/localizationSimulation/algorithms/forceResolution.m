function t = forceResolution(t,weights)
%t = forceResolution(t,<weights>)
%
%This function finds the shortest path from each node to all of the anchor
%nodes.  then, it gives the node the position defined by the bounding box
%it must be in.  Then, it refines this initial estimate by "pushing" it
%around proportional to the error with each anchor node.
%
%weights is an optional argument placed on each edge.

%find initialEstimates
if isempty(t.xyEstimate)
    t = shortestPathToAnchor(t);
%    t = boundingBox(t);
end
shortestPaths = -ones(size(t.kd));

%find the shortest paths
for i=t.anchorNodes
    anchor = (t.nodeIDs==i);
    [dummy, newNodeOrder] = sort(-anchor);
    tempkd = t.kd(newNodeOrder, newNodeOrder);
    tempkd(tempkd==-1) = zeros(1,sum(sum(logical(tempkd==-1))));
    sp = dijkstra(tempkd);
    shortestPaths(anchor, newNodeOrder(2:end)) = sp(:,2)';    
    shortestPaths(newNodeOrder(2:end), anchor) = sp(:,2);
    pathLengths(anchor, newNodeOrder(2:end)) = sp(:,4)';    
    pathLengths(newNodeOrder(2:end), anchor) = sp(:,4);
    
end

if nargin<2 | isempty(weights) 
%    weights = ones(size(t.kd));
 	maxwt =max(pathLengths,[],2);
 	weights = maxwt(:,ones(1,length(maxwt)))-pathLengths;
%	weights = 1./pathLengths;
end

%calculate a correction factor
anchorIndices = vectorFind(t.anchorNodes, t.nodeIDs);
xy = t.xy(anchorIndices,1)+t.xy(anchorIndices,2)*1i;
[X,Y] = meshgrid(xy);
anchorDists = abs(X-Y);
measuredDists = shortestPaths(anchorIndices, anchorIndices);
scalingFactor = mean(median(anchorDists./measuredDists));
shortestPaths = shortestPaths*scalingFactor;

%the following code finds the forces exerted on each node and takes the
%resultant.  then, it moves each node by the resultant.
anchorIndices = vectorFind(t.anchorNodes, t.nodeIDs);
nodeIndices = vectorFind(setdiff(t.nodeIDs,t.anchorNodes), t.nodeIDs);
xy = t.xyEstimate(:,1)+t.xyEstimate(:,2)*1i;
[X,Y] = meshgrid(xy);
direction = X-Y;
estimatedDistances = abs(X-Y);
magnitude = estimatedDistances(nodeIndices,anchorIndices)- shortestPaths(nodeIndices,anchorIndices);
deltaPosition = (direction(nodeIndices,anchorIndices)./estimatedDistances(nodeIndices,anchorIndices)).*magnitude;
%xy(nodeIndices) = xy(nodeIndices) + mean(deltaPosition,2);
xy(nodeIndices) = xy(nodeIndices) + mean(deltaPosition.*weights(nodeIndices,anchorIndices),2);
t.xyEstimate = [real(xy) imag(xy)];

