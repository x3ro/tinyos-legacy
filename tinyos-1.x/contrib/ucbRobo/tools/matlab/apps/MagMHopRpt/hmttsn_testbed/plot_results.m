function plot_results(scenfile,savefile,scenonly,stepon,saveplot,plotfile)

% Copyright (c) 2003-2004 Songhwai Oh

global G
if nargin<3, scenonly=0; end
if nargin<4, stepon=0; end
if nargin<5, saveplot=0; end

scen = load(scenfile);
result = load(savefile);

G = scen.gvs;
Tall = scen.gvs.TMAX; 

figure
axes('Box','on');
axis([scen.gvs.SR(1,1),scen.gvs.SR(1,2),scen.gvs.SR(2,1),scen.gvs.SR(2,2)]);
axis square
xlabel('x'); ylabel('y');
hold on;

if scenonly, 
    lineshape = 'r:';
    linewidth=2; 
else
    lineshape = 'r-';
    linewidth=2;
end

ally = [];
for ti=1:Tall
    ally = [ally; scen.ygold{ti}];
end
if ~scenonly
    plot(ally(:,1),ally(:,2),'k.');
end
    
for ti=1:Tall
    for m=1:scen.gvs.M
        if ti>scen.xtimes(m,1) & ti<=scen.xtimes(m,2)
            plot([scen.xtrajs{m}(1,ti-scen.xtimes(m,1)),scen.xtrajs{m}(1,ti-scen.xtimes(m,1)+1)],...
                [scen.xtrajs{m}(2,ti-scen.xtimes(m,1)),scen.xtrajs{m}(2,ti-scen.xtimes(m,1)+1)],...
                lineshape,'LineWidth',linewidth);
        end
    end
end
if scenonly
    for m=1:scen.gvs.M
        tend = size(scen.xtrajs{m},2);
        plot(scen.xtrajs{m}(1,1),scen.xtrajs{m}(2,1),'bo','MarkerSize',5,'LineWidth',2);
        text(scen.xtrajs{m}(1,1)+2,scen.xtrajs{m}(2,1),sprintf('%d',scen.xtimes(m,1)),'FontSize',16);
        text(scen.xtrajs{m}(1,tend),scen.xtrajs{m}(2,tend),sprintf('%d',scen.xtimes(m,2)),'FontSize',16);
    end
end

if ~scenonly
    for k=1:size(result.gvs.record.fulltrackinfo.track,2)
        [dummy1,dummy2] = ...
            mykalmanfilter(Tall,result.gvs.record.fulltrackinfo.track(:,k),...
            result.gvs.record.fulltrackinfo.xinit(:,k),scen.ygold,1,'b-',linewidth);
    end
end

if saveplot
    print('-djpeg50',plotfile);
end