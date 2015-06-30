function plotShortestPaths(t, strainMatrix, nodeIDs)
%plotXY(xy, anchorNodes, truexy, bx, strainMatrix, kd, nodeIDs)
%
%this function will plot the points xy and the node ids if they are passed

if ~isfield(t, 'xyEstimate') t.xyEstimate = t.xy; end
if nargin<2 | isempty(strainMatrix) strainMatrix = zeros(size(t.xyEstimate,1),size(t.xyEstimate,1)); end
if nargin<3 | isempty(nodeIDs) nodeIDs = t.nodeIDs; end
if isempty(t.xyEstimate) t.xyEstimate=t.xy; end

%transform t.xyEstimate coordinate system to the true coordinate system (for
%display comparison) by flip or rotation
if size(t.xyEstimate,1)>1 & size(t.xyEstimate,2)>1 & size(intersect(t.anchorNodes, nodeIDs),2)< 3
	indices = vectorFind(nodeIDs, t.nodeIDs);
	[xy, transform, err] = rotationalFlipTransform(t.xyEstimate(indices,:),t.xy(indices,:));
    xy=[t.xyEstimate ones(size(t.xyEstimate,1),1)]*transform;
else
    xy = t.xyEstimate;
end


%create the new adjacency matrix where nodes are adjacent if a shortest
%path goes through them
A=zeros(size(t.connectivityMatrix));
for i=t.anchorNodes
    anchor = (t.nodeIDs==i);
    [dummy, newNodeOrder] = sort(-anchor);
    tempkd = t.kd(newNodeOrder, newNodeOrder);
    tempkd(tempkd==-1) = zeros(1,sum(sum(logical(tempkd==-1))));
    sp = dijkstra(tempkd);
    connecteds=find(sp(:,4)>0);
    if connecteds
        A(sub2ind(size(A),newNodeOrder(sp(connecteds,1)),newNodeOrder(sp(connecteds,3))))=1;
        A(sub2ind(size(A),newNodeOrder(sp(connecteds,3)),newNodeOrder(sp(connecteds,1))))=1;
	end
end
            
cla
[X,Y] = gplot(t.connectivityMatrix>0 & t.kd>0,t.xy);
plot(X,Y, 'color',[.8 .8 .8]);
hold on
[X,Y] = gplot(A,t.xy);
plot(X,Y, 'b');
plot(t.xy(:,1),t.xy(:,2),'.k'); 
%plot(xy(:,1),xy(:,2),'ob')
quiver(t.xy(:,1),t.xy(:,2),xy(:,1)-t.xy(:,1),xy(:,2)-t.xy(:,2),0,'b'); %remove the zero to automatically scale the arrow to fit screen
plot(xy(vectorFind(t.anchorNodes, t.nodeIDs),1),xy(vectorFind(t.anchorNodes, t.nodeIDs),2),'xr', 'MarkerSize', 15,'LineWidth',2)
hold off
for i = 1:size(xy,1)
%    text(xy(i,1),xy(i,2),[' ',num2str(nodeIDs(i))], 'color',[0 0 1])
    text(t.xy(i,1),t.xy(i,2),[' ',num2str(t.nodeIDs(i))])
end
%axis off
%axis tight
%set(gca,'xcolor', [.7 .7 .7],'ycolor', [.7 .7 .7])
set(gcf,'Color','white')

