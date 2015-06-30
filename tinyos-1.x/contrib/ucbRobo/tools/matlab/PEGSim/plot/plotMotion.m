function plotMotion

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
plotState.P = plot(P.pos(1,end),P.pos(2,end),'ro','MarkerSize',12,'LineWidth',2);
plotState.E = plot(E.pos(1,end),E.pos(2,end),'g*','MarkerSize',12,'LineWidth',2);

% plot paths
plotState.PfullPath = plot(P.pos(1,:),P.pos(2,:),'m^-','LineWidth',2);
plotState.EfullPath = plot(E.pos(1,:),E.pos(2,:),'co-','LineWidth',2);

title(sprintf('Pursuer and Evader positions until T=%.1f',T));
legend([plotState.P plotState.E plotState.PfullPath plotState.EfullPath],...
       'Pursuer Position','Evader Position','Pursuer Path','Evader Path',...
       'Location','BestOutside');

hold off;
