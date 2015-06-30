function t = plotMultihopErrorDistribution(t)
%t = plotMultihopErrorDistribution(t)
%
%This function finds the shortest path from each node to all of the anchor
%nodes.  then, it gives the node the position with the lease error given
%those distances (using least squares).  This algorithm weights the effect
%of each anchor node based on the number of hops of shortest path found.

shortestPaths = -ones(size(t.kd));
pathLengths = zeros(size(t.kd));

%the following code finds the shortest paths from each node to every anchor
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

%calculate a correction factor
mobileIndices = find(vectorFind(setdiff(t.nodeIDs, t.anchorNodes), t.nodeIDs));
anchorIndices = vectorFind(t.anchorNodes, t.nodeIDs);
xy = t.xy(:,1)+t.xy(:,2)*1i;
[X,Y] = meshgrid(xy);
trueDists = abs(X-Y);
%error = trueDists(mobileIndices, anchorIndices)./shortestPaths(mobileIndices, anchorIndices);
error = trueDists(mobileIndices, anchorIndices)-shortestPaths(mobileIndices, anchorIndices);
error=error/max(max(t.kd));

[f,xi] = ksdensity(error(:));
plot(xi,f,'b','lineWidth',2);
[mu, sigma] = normfit(error(:));
a=axis;
%sigma=sigma*4;
x=a(1):(a(2)-a(1))/100:a(2);
y = normpdf(x,mu,sigma);
hold on
plot(x,y,':k','lineWidth',2)

y = laplacepdf(x,mu,sqrt(sigma^2/2));
plot(x,y,'--r','lineWidth',2)
hold off

legend('Emprical Distribution','Normal Fit', 'Laplace Fit')
title('Multi-hop Distance Error Distribution')
xlabel('Distance Estimate Error (relative to maximum range)')
%ylabel

function y=laplacepdf(x, alpha, beta)
y = exp(-abs(x-alpha)/beta)*(1/(2*beta));