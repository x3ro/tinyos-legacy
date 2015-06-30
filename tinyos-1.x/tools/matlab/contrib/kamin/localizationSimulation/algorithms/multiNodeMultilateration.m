function t = multiNodeMultilateration(t)
%t = multiNodeMultilateration(t)
%
%This function ignores all distances except those to anchor nodes and, if
%there are enough, will create a system of equations to JOINTLY solve for the unique xy
%coordinates of all mobile nodes.

%this function doesn't work yet.... it has to be made into a quadratic
%programming problem or something.

mobileNodes = setDiff(t.nodeIDs, t.anchorNodes);
mobileIndices = vectorFind(mobileNodes, t.nodeIDs);
anchorIndices = vectorFind(t.anchorNodes, t.nodeIDs);
if isempty(t.xyEstimate) t.xyEstimate = zeros(size(t.xy)); end
t.xyEstimate(anchorIndices,:) = t.xy(anchorIndices,:);

x = t.xyEstimate(:);
a = [];
b = [];
row = 0;
for node = mobileNodes
    index = find(t.nodeIDs == node);
    anchors = find(t.kd(node,:)>0 & anchorIndices');
    neighbors = find(t.kd(node,:)>0);
    if length(neighbors)>2
        [dummy, dummy,r] = regress(t.xy(neighbors,2), [ones(length(neighbors),1) t.xy(neighbors,1)]);
        if any(r~= 0) %if all anchors are not colinear
            for i = 1:length(neighbors)-1
                row = row + 1;
                a(row,index) = t.xy(anchors(i),1) - t.xy(anchors(end),1);
                a(i,2) = t.xy(anchors(i),2) - t.xy(anchors(end),2);
                b(i) = t.kd(node, anchors(i))^2 - t.kd(node, anchors(end))^2 - t.xy(anchors(i),1)^2 + t.xy(anchors(end),1)^2 - t.xy(anchors(i),2)^2 + t.xy(anchors(end),2)^2;
            end
            [xy, flag] = lsqr(a,b');
            t.xyEstimate(node,:) = -xy./2';
        end
    end
end
