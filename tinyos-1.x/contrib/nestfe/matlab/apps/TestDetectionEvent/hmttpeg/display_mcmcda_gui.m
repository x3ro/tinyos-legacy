function display_mcmcda_gui(mcmcda_guihandles,curr_time,plikM,doPEG,E2P,evaders,fuseY,scen)

% Copyright (c) 2005 Songhwai Oh

global gvs 
global G_displayTracks

% plot detection
axes(mcmcda_guihandles.detection_axes);
cla;
axis equal
set(mcmcda_guihandles.detection_axes,'XLim',gvs.sw.SR(1,:),'YLim',gvs.sw.SR(2,:),'Box','on');
hold on
for n=1:gvs.sw.N
    plot(gvs.sw.pos(n,1),gvs.sw.pos(n,2),'k.','MarkerSize',10);
    if ~isempty(intersect(gvs.yobs_raw{curr_time},n))
        %circle(gvs.sw.pos(n,:),gvs.sw.Rs,50,'r-'); 
        plot(gvs.sw.pos(n,1),gvs.sw.pos(n,2),'r.','MarkerSize',30);
    end
end

% plot fusion
axes(mcmcda_guihandles.fusion_axes);
cla;
axis equal
set(mcmcda_guihandles.fusion_axes,'XLim',[0,size(plikM,1)+1],'YLim',[0,size(plikM,2)+1],'Box','on');
hold on
imagesc(plikM');
shading interp;
if ~isempty(fuseY)
    plot(fuseY(:,1)./gvs.grid.unitlen,fuseY(:,2)./gvs.grid.unitlen,'ro','MarkerSize',10,'LineWidth',3);
end

% plot tracks
axes(mcmcda_guihandles.track_axes);
cla;
if G_displayTracks.addBackground
    hold off;
    %image( G_displayTracks.xx.*G_displayTracks.sx , G_displayTracks.yy.*G_displayTracks.sy , G_displayTracks.mapImage );
    image( G_displayTracks.xx , G_displayTracks.yy , G_displayTracks.mapImage );
    set( mcmcda_guihandles.track_axes , 'YDir' , 'normal' );
    %set( mcmcda_guihandles.track_axes , 'YDir' , 'reverse' );
    hold on;
else
    axis equal
    set(mcmcda_guihandles.track_axes,'XLim',gvs.sw.SR(1,:),'YLim',gvs.sw.SR(2,:),'Box','on');
    hold on;
end
if ~isempty(scen)
    for t=1:curr_time
        for m=1:scen.gvs.M
            if t>scen.xtimes(m,1) & t<=scen.xtimes(m,2)
                plot([scen.xtrajs{m}(1,t-scen.xtimes(m,1)),scen.xtrajs{m}(1,t-scen.xtimes(m,1)+1)],...
                    [scen.xtrajs{m}(2,t-scen.xtimes(m,1)),scen.xtrajs{m}(2,t-scen.xtimes(m,1)+1)],'r-');
            end
        end
    end
end

%global G_displayTracks
%G_displayTracks.tracks = {};
if ~isempty(gvs.record.trackinfo.track)
    for k=1:size(gvs.record.trackinfo.track,2)
        if length(find(gvs.record.trackinfo.track(:,k)>0))>=gvs.disp.num_min_detections_for_track
            [dummy1,dummy2] = ...
                mykalmanfilter(length(gvs.yobs_win),gvs.record.trackinfo.track(:,k),...
                gvs.record.trackinfo.xinit(:,k),gvs.yobs_win,1,'r-',2);
	    %G_displayTracks.tracks{ k } = dummy1(1:2,:);
        end
    end
end
%displayTracks(mcmcda_guihandles.track_axes);

if ~isempty(gvs.record.fulltrackinfo.track)
    %mycolors = {'b-','g-','m-','c-'};
    [full_T,full_K] = size(gvs.record.fulltrackinfo.track);
    fullxinit = zeros(4,full_K);
    for k=1:full_K
        start_time = max(1,full_T - gvs.disp.winsize + 1);
        if start_time>1
            final_time = gvs.disp.winsize;
        else
            final_time = full_T;
        end
        if length(find(gvs.record.fulltrackinfo.track(start_time:full_T,k)>0))>=gvs.disp.num_min_detections_for_track 
            fullxinit(:,k) = get_xinit(gvs.record.fulltrackinfo.track(start_time:full_T,k),gvs.yobs(start_time:full_T));
            [dummy1,dymmy2,dummy3] ...
                = mykalmanfilter(final_time,gvs.record.fulltrackinfo.track(start_time:full_T,k),...
                fullxinit(:,k),gvs.yobs(start_time:full_T),1,'r-',3);
        end
    end
end

% plot PEG assignment
if doPEG
    shapeP{1} = 'sr'; shapeP{2}='sm'; shapeP{3}='sg';shapeP{4}='sc';shapeP{5}='sb';shapeP{6}='sk';
    shapeE{1} = '*r'; shapeE{2}='*m'; shapeE{3}='*g';shapeE{4}='*c';shapeE{5}='*b';shapeE{6}='*k';
    for n=1:length(E2P)
        if E2P(n)~=0
            plot(50/60*(evaders.Px(n)+20),50/60*(evaders.Py(n)-110),...
                shapeE{E2P(n)},'MarkerSize',15,'linewidth',3);
        end
    end
    for n=1:gvs.peg.Np
        plot(50/60*(gvs.peg.Px(n,curr_time)+20),50/60*(gvs.peg.Py(n,curr_time)-110),...
            shapeP{n},'MarkerSize',10,'linewidth',3);
    end
end

drawnow
if G_displayTracks.render 
    renderAxes(mcmcda_guihandles.track_axes);
end

stopme=1;