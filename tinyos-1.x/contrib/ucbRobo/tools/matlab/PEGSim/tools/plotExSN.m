function plotExSN(SN,fields)
% plotExSN(SN,fields)
% inputs: SN     Input sensor network structure
%         fields A vector of 1 or 0 entries to determine whether to plot a
%                particular type of attribute in the SN
%         [nodes sensing_radius comm_radius routing_tree playing_field]
% Roughly the same as plotSN, except we can also plot the boundaries of the
% game, as defined by the dimensions of the sensor network.  Ex stands for
% existing sensor network.

global plotExState;

if isempty(plotExState)
  initPlotExState;
end

if (nargin < 2) 
  fields = [1 1 1 0 1]; %default
end

figure(plotExState.SNfignum);
hold on;

% plot sensing radius
if fields(2)
  for i = 1:SN.n
    r = SN.nodes(3,i);
    plotExState.senseR(end+1) = rectangle('position',[(SN.nodes(1,i) - r) ...
		    (SN.nodes(2,i) - r) 2*r 2*r], 'curvature', [1 1], ...
					'facecolor', 'y','edgecolor','y');
  end
end

% plot communication radius
if fields(3)
  for i = 1:SN.n
    r = SN.nodes(4,i);
    plotExState.commR(end+1) = rectangle('position',[(SN.nodes(1,i) - r) (SN.nodes(2,i) - r) 2*r 2*r], 'curvature', [1 1]);
  end
end

% plot routing tree
if fields(4)
  for i = 1:SN.n
    linksArr = unique(SN.pathMat(i,:));
    for j = linksArr(2:end) %unique also sorts, remove 0 which is 1st entry
      plotExState.rTree(end+1) = plot([SN.nodes(1,i) SN.nodes(1,j)], ...
		                    [SN.nodes(2,i) SN.nodes(2,j)]);
    end
  end
end

% plot nodes
if fields(1)
  axis([-plotExState.border (SN.dimX + plotExState.border) -plotExState.border (SN.dimY + plotExState.border)])
  plotExState.nodes = plot(SN.nodes(1,:),SN.nodes(2,:),'.');
end

% plot playing field
if (fields(5))
    rectangle('position',[0 0 SN.dimX SN.dimY])
end
hold off;
