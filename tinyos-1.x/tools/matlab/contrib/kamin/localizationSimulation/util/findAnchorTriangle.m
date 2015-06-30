function [triangleQuality, bestAnchors] = findAnchorTriangle(t, nodeID, penalty)
%[triangleQuality, bestAnchors] = findAnchorTriangle(t, nodeID,<penalty>)
%
%This function finds the three anchors that are best for a certain node.
%
%To do this, it tries all combinations of triangles. and tests them for
%whether they have all acute angles and for whether the nodeID is somewhere
%near that triangle.  Meanwhile, it also keeps track of the best so far.
%the best quality is 1.  acceptable quality is 3 or lower.
%
%penalty is an optional parameter that can be used to penalize for using an
%edge.  for example, if the edges represent multi-hop distance estimates,
%you may want to penalize each edge by the number of hops.

warning off MATLAB:divideByZero
triangleQuality = 1/0;

if length(t.anchorNodes)<3
    bestAnchors = t.anchorNodes;
    return
end

node = find(t.nodeIDs == nodeID);
bestAnchors = [];
bestMeasure = 1/0;
for i=1:length(t.anchorNodes)
    anchori=find(t.anchorNodes(i)==t.nodeIDs);
    for j=i+1:length(t.anchorNodes)
        anchorj=find(t.anchorNodes(j)==t.nodeIDs);
        for k=j+1:length(t.anchorNodes)
            anchork=find(t.anchorNodes(k)==t.nodeIDs);
            
            anchors = [anchori anchorj anchork];
            xy = t.xy(anchors,1)+t.xy(anchors,2)*1i;
            [X,Y] = meshgrid(xy);
            dist = abs(X-Y);
            aDists = [dist(1,2) dist(1,3) dist(2,3)];
            anchorDists = sort(aDists);
            angle = acos( (anchorDists(3)^2 -anchorDists(1)^2 -anchorDists(2)^2)/(-2*anchorDists(1)*anchorDists(2)));
            angleMeasure = ceil((angle-pi/3)/(pi/9));
%            angleMeasure = sqrt(anchorDists(3)^2 -anchorDists(1)^2 -anchorDists(2)^2);

            nodeDists = t.kd(node,anchors);
            distDiff = (nodeDists([1 1],:)./aDists([1 1 2; 2 3 3]));
%            distDiff = nodeDists-anchorDists;
            distanceMeasure = max(max(distDiff));
            
            measure = angleMeasure + distanceMeasure;
            if nargin==3 & ~isempty(penalty) 
                measure = measure+ max(penalty(node, anchors));
            end
            
            if angleMeasure <=5 & distanceMeasure<=5 & measure < bestMeasure %don't use any triangles of more than 120 degress or farther than 1.5 time the edge length.
                bestAnchors = anchors;
                bestMeasure = measure;
                triangleQuality = min(triangleQuality, max(angleMeasure, distanceMeasure));
            end
        end
    end
end