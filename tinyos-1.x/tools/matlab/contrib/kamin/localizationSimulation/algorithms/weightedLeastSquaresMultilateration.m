function t = weightedLeastSquaresMultilateration(t, weights)
%t = weightedLeastSquaresMultilateration(t, weights)
%
%This function ignores all distances except those to anchor nodes and, if
%there are enough, will create a system of equations to solve for the unique xy
%coordinates of each mobile node.   Mobile nodes without unique xy coords
%are set to the origin.

 mobileNodes = setDiff(t.nodeIDs, t.anchorNodes);
mobileIndices = find(vectorFind(mobileNodes, t.nodeIDs));
anchorIndices = vectorFind(t.anchorNodes, t.nodeIDs);
if isempty(t.xyEstimate) t.xyEstimate = zeros(size(t.xy)); end
t.xyEstimate(anchorIndices,:) = t.xy(anchorIndices,:);

for node = mobileIndices'
    anchors = find(t.kd(node,:)>0 & anchorIndices');
    a=[];
    b=[];
    if length(anchors)>2
        [dummy, dummy,r] = regress(t.xy(anchors,2), [ones(length(anchors),1) t.xy(anchors,1)]);
        if all(r<10) %if all anchors are not colinear
            warning(['Node ' num2str(node) ' is using colinear anchor points']);
        end
        for i = 1:length(anchors)-1
            a(i,1) = (t.xy(anchors(i),1) - t.xy(anchors(end),1))*weights(node,anchors(i));
            a(i,2) = (t.xy(anchors(i),2) - t.xy(anchors(end),2))*weights(node,anchors(i));
            b(i) = (t.kd(node, anchors(i))^2 - t.kd(node, anchors(end))^2 - t.xy(anchors(i),1)^2 + t.xy(anchors(end),1)^2 - t.xy(anchors(i),2)^2 + t.xy(anchors(end),2)^2)*weights(node,anchors(i));
       end
        [xy, flag] = lsqr(a,b');
        t.xyEstimate(node,:) = -xy./2';
    end
end
