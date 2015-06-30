function boolean = iscolinear(anchorXY, distances)
%boolean = iscolinear(anchorXY, distances)
%
%This function returns whether or not a set of nodes are colinear
%with respect to another node.  
%
%anchorXY are the xy coords of the nodes in question.  distances is the
%vector of distances from each of these nodes to the node being localized.

anchors = 1:size(anchorXY,1);

[XY1,XY2] = meshgrid(anchorXY(:,1),anchorXY(:,2));
dist = sqrt((XY1 - XY1').^2 + (XY2 - XY2').^2); 

[dummy, dummy,r] = regress(anchorXY(anchors,2), [ones(length(anchors),1) anchorXY(anchors,1)]);
[maxResidual, index] = max(r);

anchors(index)=[];

if maxResidual > distances(index) & any( max(dist(anchors,anchors),[],2)>distances(anchors)')
    boolean=1;
else 
    boolean=0;
end




