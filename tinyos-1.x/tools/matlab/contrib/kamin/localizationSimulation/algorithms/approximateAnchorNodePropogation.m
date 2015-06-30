function t = approximateAnchorNodePropogation(t)
%t = approximateAnchorNodePropogation(t)
%
%this function uses anchorNode propogation.  However, when no unique solution
%exists we use a center-of-mass approximate to those anchor nodes that do
%exist.  It does this first for nodes with two attached anchors and then
%for nodes with only one.

%this function works like shit
%as it turns out, if you want to do exact least squares multilateration,
%you cannot make any approximations because that small amount of error will
%propogate through your network like crazy.

closeCutoff = 3; %nodes within 3 centimeters of an anchor node can be said to be at the anchor node
oldAnchorNodes = [];
tOriginal = t;
t.xyEstimate = zeros(size(t.xy));

while length(t.anchorNodes) ~= length(oldAnchorNodes) %approximate to those with only one anchor
%    while length(t.anchorNodes) ~= length(oldAnchorNodes) %approximate to those with only two anchors
        while length(t.anchorNodes) ~= length(oldAnchorNodes)
            t = leastSquaresMultilateration(t);
            oldAnchorNodes = t.anchorNodes;
            t.anchorNodes = t.nodeIDs(union(find(t.xyEstimate(:,1)), find(t.xyEstimate(:,2))));
            t.xy(t.xyEstimate>0) = t.xyEstimate(t.xyEstimate>0);
        end
%         mobileNodes = setDiff(t.nodeIDs, t.anchorNodes);		
% 		anchorIndices = vectorFind(t.anchorNodes, t.nodeIDs);		
%         newNodes = mobileNodes(find(sum(t.kd(mobileNodes, anchorIndices)>0,2) ==2));
%         t = anchorNodeCenterOfMass(t, t.nodeIDs(newNodes));
%         oldAnchorNodes = t.anchorNodes;
%         t.anchorNodes = t.nodeIDs(union(find(t.xyEstimate(:,1)), find(t.xyEstimate(:,2))));
%         t.xy(t.xyEstimate>0) = t.xyEstimate(t.xyEstimate>0);
%     end
    mobileNodes = setDiff(t.nodeIDs, t.anchorNodes);		
	anchorIndices = vectorFind(t.anchorNodes, t.nodeIDs);		
    newNodes = mobileNodes(find(sum(t.kd(mobileNodes, anchorIndices)>0 & t.kd(mobileNodes, anchorIndices)<closeCutoff,2)));
    t = anchorNodeCenterOfMass(t, t.nodeIDs(newNodes));
    oldAnchorNodes = t.anchorNodes;
    t.anchorNodes = t.nodeIDs(union(find(t.xyEstimate(:,1)), find(t.xyEstimate(:,2))));
    t.xy(t.xyEstimate>0) = t.xyEstimate(t.xyEstimate>0);
end
tOriginal.xyEstimate = t.xyEstimate;
t = tOriginal;
