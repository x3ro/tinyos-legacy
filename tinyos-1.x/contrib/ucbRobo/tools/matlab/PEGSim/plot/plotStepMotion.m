function plotStepMotion

global P;
global E;
global plotState;
global T;

if isempty(plotState)
  initPlotState;
end

figure(plotState.SNfignum);
hold on;
% plot pursuer & evader
if ishandle(plotState.P) delete(plotState.P); end
if ishandle(plotState.E) delete(plotState.E); end
plotState.P = plot(P.pos(1,end),P.pos(2,end),'ro');
plotState.E = plot(E.pos(1,end),E.pos(2,end),'gx');
% plot paths
plotState.Ppath(end+1) = plot(P.pos(1,end-1:end),P.pos(2,end-1:end),'m','LineWidth',4);
plotState.Epath(end+1) = plot(E.pos(1,end-1:end),E.pos(2,end-1:end),'c','LineWidth',4);

title(sprintf('Pursuer and Evader positions until T=%.1f',T));
legend([plotState.P plotState.E plotState.Ppath(end) plotState.Epath(end)],...
       'Pursuer Position','Evader Position','Pursuer Path','Evader Path',...
       'Location','BestOutside');
hold off;
