function initPlotState
  
global plotState;
global SN;


plotState.SNfignum = 1;
plotState.Moviefignum = 2;
plotState.PktHistfignum = 3;
plotState.TestParamsfignum = 10;
plotState.TestUfignum = 11;

if ~isempty(SN)
    plotState.SNaxis = [0 SN.dimX 0 SN.dimY];
else
    plotState.SNaxis = [0 25 0 25];
end
%plotState.nodes can be uninitialized
plotState.border = 5;
plotState.senseR = [];
plotState.commR = [];
plotState.rTree = [];
if (exist('plotState.route') && ishandle(plotState.route))
    delete(plotState.route); 
end
plotState.route = [];

% Stepwise Motion Plots
if (exist('plotState.P') && ishandle(plotState.P))
    delete(plotState.P);
end
if (exist('plotState.E') && ishandle(plotState.E))
    delete(plotState.E);
end
if (exist('plotState.Ppath') && ishandle(plotState.Ppath))
    delete(plotState.Ppath);
end
if (exist('plotState.Epath') && ishandle(plotState.Epath))
    delete(plotState.Epath);
end
plotState.P = [];
plotState.E = [];
plotState.Ppath = [];
plotState.Epath = [];

% Motion Annotation Plot
if (exist('plotState.Panno') && ishandle(plotState.Panno))
    delete(plotState.Panno);
end
if (exist('plotState.Eanno') && ishandle(plotState.Eanno))
    delete(plotState.Eanno  );
end
plotState.Panno = [];
plotState.Eanno = [];

% Final Motion Plot
if (exist('plotState.PfullPath') && ishandle(plotState.PfullPath))
    delete(plotState.PfullPath');
end
if (exist('plotState.EfullPath') && ishandle(plotState.EfullPath))
    delete(plotState.EfullPath);
end
plotState.PfullPath = [];
plotState.EfullPath = [];

% Motion Movie
plotState.Pmov = [];
plotState.Emov = [];

% initialize axis settings only once for plots
figure(plotState.SNfignum);
axis(plotState.SNaxis);
