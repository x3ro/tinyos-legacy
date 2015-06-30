function plotRoute(rcvpkts)
% Plots the routes of successful tranmissions
  
global SN;
global plotState;

if isempty(plotState)
  initPlotState;
end

routeColor = ['y' 'm' 'c' 'r' 'g' 'b' 'w' 'k'];
figure(plotState.SNfignum);
hold on;
%remove stale packet tranmission routes
if ishandle(plotState.route) delete(plotState.route); end

% % replot nodes
% if fields(1)
%   axis([-plotState.border (SN.dimX + plotState.border) -plotState.border (SN.dimY + plotState.border)])
%   plotState.nodes = plot(SN.nodes(1,:),SN.nodes(2,:),'.');
% end

% plot routing tree
for i = 1:size(rcvpkts,2)
  pkt = rcvpkts(:,i);
  linksArr = SN.routePath{pkt(2),pkt(5)};
  curr = pkt(2);
  for nxt = linksArr
    % to determine unique colors for up to 4 routes
    plotState.route(end+1) = plot([SN.nodes(1,curr) SN.nodes(1,nxt)], ...
				  [SN.nodes(2,curr) SN.nodes(2,nxt)], ...
				  'color', ...
				  routeColor(mod(i,size(routeColor,2))+1));
    curr = nxt;
  end
end
hold off;
