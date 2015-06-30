function annoMotion(stepSize)
% annotates the plot of the pursuer's motion with numbers for every 10
% sampling intervals of time

global P;
global E;
global plotState;
global T;
if isempty(plotState)
  initPlotState;
end

if (nargin == 0)
    stepSize = 10
end

figure(plotState.SNfignum);
hold on;
% plot pursuer & evader
if ishandle(plotState.Panno) delete(plotState.Panno); end
if ishandle(plotState.Eanno) delete(plotState.Eanno); end
for i = 1:stepSize:size(P.pos,2)
    plotState.Panno(:,i) = text(P.pos(1,i),P.pos(2,i),num2str(i),'Color','r');
end
for i = 1:stepSize:size(E.pos,2)
    plotState.Eanno(:,i) = text(E.pos(1,i),E.pos(2,i),num2str(i),'Color','b');
end
hold off;
