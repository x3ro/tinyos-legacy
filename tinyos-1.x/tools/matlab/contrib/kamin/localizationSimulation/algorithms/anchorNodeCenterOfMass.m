function t = anchorNodeCenterOfMass(t, nodeIDs)
%t = anchorNodeCenterOfMass(t)
%
%this function assignes each node (or only those specified in the argument)
%the center of mass of all connected anchor nodes
%
%nodeIDs must be a row vector

if nargin <2 | isempty(nodeIDs) nodeIDs = setDiff(t.nodeIDs, t.anchorNodes); end
anchorIndices = vectorFind(t.anchorNodes, t.nodeIDs);
if isempty(t.xyEstimate) t.xyEstimate = zeros(size(t.xy)); end

for node = nodeIDs
    anchors = find(t.kd(find(node == t.nodeIDs),:)>0 & anchorIndices');
    if length(anchors)>0
        t.xyEstimate(find(node == t.nodeIDs),:) = sum(t.xyEstimate(anchors,:))/length(anchors);
    end
end
