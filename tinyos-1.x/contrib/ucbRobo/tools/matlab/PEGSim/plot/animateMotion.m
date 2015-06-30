function M = animateMotion
% Animates the motion of the pursuit evasion graph using

global plotState;
global P;
global E;
global dT;

figure(plotState.Moviefignum);
axis(plotState.SNaxis);
clf(plotState.Moviefignum);
hold on;
numSteps = floor(1/dT);
cnt = 1;
for i = 1:numSteps:size(P.pos,2)
    % plot paths    
    iNext = min(i+numSteps,size(P.pos,2));
    h1 = plot(P.pos(1,i:iNext),P.pos(2,i:iNext),'m',...
        'LineWidth',2);
    h2 = plot(E.pos(1,i:iNext),E.pos(2,i:iNext),'c',...
        'LineWidth',2);

    % plot pursuer & evader
    if ishandle(plotState.Pmov) delete(plotState.Pmov); end
    if ishandle(plotState.Emov) delete(plotState.Emov); end
    plotState.Pmov = plot(P.pos(1,iNext),P.pos(2,iNext),'ro',...
                    'MarkerSize',15, 'LineWidth',2);
    plotState.Emov = plot(E.pos(1,iNext),E.pos(2,iNext),'g*',...
                    'MarkerSize',15, 'LineWidth',2);

    title(sprintf('Pursuer and Evader positions at T = %.1f', i*dT));
    legend([plotState.Pmov plotState.Emov h1 h2],'Pursuer Position',...
            'Evader Position','Pursuer Path','Evader Path',...
            'Location','BestOutside');

    M(cnt) = getframe;
    cnt = cnt + 1;
end
hold off;

movie(M,1,1);
%movie2avi(M,'PEGSim.avi','fps',1);
