function plotSN(fields)
% inputs: fields A vector of 1 or 0 entries to determine whether to plot a
%                particular type of attribute in the SN
%         [nodes sensing_radius comm_radius routing_tree]
  
  
global SN;
global plotState;

if isempty(plotState)
  initPlotState;
end

if (nargin == 0) 
  fields = [1 1 1 0]; %default
end

figure(plotState.SNfignum);
hold on;
% plot sensing radius
if fields(2)
  for i = 1:SN.n
    r = SN.nodes(3,i);
    plotState.senseR(end+1) = rectangle('position',[(SN.nodes(1,i) - r) ...
		    (SN.nodes(2,i) - r) 2*r 2*r], 'curvature', [1 1], ...
					'facecolor', 'y','edgecolor','y');
  end
end

% plot communication radius
if (fields(3) == 1)
  for i = 1:SN.n
    r = SN.nodes(4,i);
    plotState.commR(end+1) = rectangle('position',[(SN.nodes(1,i) - r) ...
		    (SN.nodes(2,i) - r) 2*r 2*r], 'curvature', [1 1]);
  end
elseif (fields(3) == 2)
    for i = 1:SN.n
        r = SN.nodes(4,i);
        plotState.commR(end+1) = rectangle('position',...
        [(SN.nodes(1,i) - r)  (SN.nodes(2,i) - r) 2*r 2*r],...
        'curvature', [1 1],	'facecolor', 'c','edgecolor','c');
    end
end

% plot routing tree
if fields(4)
  for i = 1:SN.n
    linksArr = unique(SN.pathMat(i,:));
    for j = linksArr(2:end) %unique also sorts, remove 0 which is 1st entry
      plotState.rTree(end+1) = plot([SN.nodes(1,i) SN.nodes(1,j)], ...
		                    [SN.nodes(2,i) SN.nodes(2,j)]);
    end
  end
end

% plot nodes (last so will show in picture)
if fields(1)
  axis([-plotState.border (SN.dimX + plotState.border) ...
	-plotState.border (SN.dimY + plotState.border)])
  plotState.nodes = plot(SN.nodes(1,:),SN.nodes(2,:),'.');
end

hold off;
