function gen_swobs_PIR(trajfile,swobsfile,layout,Rs,dist,unitlen,showfig)

% Copyright (c) 2005 Songhwai Oh

tr = load(trajfile);

% movfilename = sprintf('%s.avi',trajfile);
% mov = avifile(movfilename,'FPS',2,'QUALITY',100,'compression','none');

% sensor network parameters
gvs.sw.dist = dist;
gvs.sw.pos = [];
switch layout
    case {'uniform'}
        for x=tr.gvs.SR(1,1)+gvs.sw.dist/2:gvs.sw.dist:tr.gvs.SR(1,2)-gvs.sw.dist/2
            for y=tr.gvs.SR(2,1)+gvs.sw.dist/2:gvs.sw.dist:tr.gvs.SR(2,2)-gvs.sw.dist/2
                gvs.sw.pos = [gvs.sw.pos; x,y];
            end
        end
    case {'alternate'}
        alt = 1;
        for y=tr.gvs.SR(2,1)+gvs.sw.dist/2:gvs.sw.dist:tr.gvs.SR(2,2)-gvs.sw.dist/2
            if alt==1
                for x=tr.gvs.SR(1,1)+gvs.sw.dist/2:gvs.sw.dist:tr.gvs.SR(1,2)-gvs.sw.dist/2
                    gvs.sw.pos = [gvs.sw.pos; x,y];
                end
            else
                for x=tr.gvs.SR(1,1)+gvs.sw.dist:gvs.sw.dist:tr.gvs.SR(1,2)-gvs.sw.dist/2
                    gvs.sw.pos = [gvs.sw.pos; x,y];
                end
            end
            alt = ~alt;
        end
    otherwise 
        error('unknown sensor network layout');
end
gvs.sw.N = length(gvs.sw.pos);
gvs.sw.Rs = Rs;
gvs.sw.Pd = .9*ones(1,gvs.sw.N);
gvs.sw.Pf = 0.02*ones(1,gvs.sw.N); 
gvs.sw.SR = [min(gvs.sw.pos(:,1)) max(gvs.sw.pos(:,1)); ...
             min(gvs.sw.pos(:,2)) max(gvs.sw.pos(:,2))]; 
gvs.sw.SR(:,1) = gvs.sw.SR(:,1) - gvs.sw.Rs;
gvs.sw.SR(:,2) = gvs.sw.SR(:,2) + gvs.sw.Rs; 
fprintf(1,'number of sensors = %d\n',gvs.sw.N);

% detection grid parameters
gvs.grid.unitlen = unitlen;
gvs.grid.xN = floor((gvs.sw.SR(1,2)-gvs.sw.SR(1,1))/gvs.grid.unitlen);
gvs.grid.yN = floor((gvs.sw.SR(2,2)-gvs.sw.SR(2,1))/gvs.grid.unitlen);
gvs.grid.N = gvs.grid.xN * gvs.grid.yN;
fprintf('number of grid points = %d\n',gvs.grid.N);

% grid assignment
gvs.grid.sensV = cell(1,gvs.grid.N);
for n=1:gvs.grid.N
    [ix,iy] = ind2sub([gvs.grid.xN,gvs.grid.yN],n);
    distM = (gvs.sw.pos - repmat(gvs.grid.unitlen*[ix,iy]-gvs.grid.unitlen/2,gvs.sw.N,1)).^2;
    distM = sqrt(sum(distM,2));
    gvs.grid.sensV{n} = find(distM<gvs.sw.Rs);
end

% grid clustering
gvs.grid.cluster = [];
% for n=1:gvs.grid.N
%     curr_sensV = gvs.grid.sensV{n};
%     curr_sensV_len = length(curr_sensV);
%     old_cluster = 0;
%     for m=1:length(gvs.grid.cluster)
%         this_sensV = gvs.grid.sensV{gvs.grid.cluster{m}(1)};
%         if curr_sensV_len==length(this_sensV) & all(curr_sensV==this_sensV)
%             old_cluster = m;
%             break
%         end
%     end
%     if old_cluster>0
%         gvs.grid.cluster{old_cluster} = [gvs.grid.cluster{old_cluster},n];
%     else
%         gvs.grid.cluster{end+1} = n;
%     end
% end
% fprintf('number of grid clusters = %d\n',length(gvs.grid.cluster));

% generate measurements
gvs.sw.raw.x = cell(1,tr.gvs.TMAX);
gvs.sw.raw.sy = cell(1,tr.gvs.TMAX);
for t=1:tr.gvs.TMAX
    % detection
    syt = [];
    xt = [];
    for m=1:tr.gvs.M
        if t>=tr.xtimes(m,1) & t<=tr.xtimes(m,2)
            xpos = tr.xtrajs{m}(:,t-tr.xtimes(m,1)+1);
            xt = [xt; xpos(1:2)'];
            distM = (gvs.sw.pos - repmat(xpos(1:2)',gvs.sw.N,1)).^2;
            distM = sqrt(sum(distM,2));
            sensV = find(distM<gvs.sw.Rs);
            if ~isempty(sensV)
                for nn=1:length(sensV)
                    if rand(1)<gvs.sw.Pd(sensV(nn))
                        syt = [syt; sensV(nn)];
                    end
                end
            end
        end
    end
    gvs.sw.raw.x{t} = xt;
    % false detection
    for n=1:gvs.sw.N
        if rand(1)<gvs.sw.Pf(n)
            syt = [syt; n];
        end
    end
    gvs.sw.raw.sy{t} = syt;
    
    if showfig
        if t==1
            hfig = figure;
        else
            clf
        end
        axis([tr.gvs.SR(1,1),tr.gvs.SR(1,2),tr.gvs.SR(2,1),tr.gvs.SR(2,2)]);
        axis square
        hold on
        for n=1:gvs.sw.N
            plot(gvs.sw.pos(n,1),gvs.sw.pos(n,2),'k.');
        end
        for n=1:length(gvs.sw.raw.sy{t})
            circle(gvs.sw.pos(gvs.sw.raw.sy{t}(n),:),gvs.sw.Rs,100,'r-');
            plot(gvs.sw.pos(gvs.sw.raw.sy{t}(n),1),gvs.sw.pos(gvs.sw.raw.sy{t}(n),2),'r.');
        end
        if ~isempty(gvs.sw.raw.x{t})
            plot(gvs.sw.raw.x{t}(:,1),gvs.sw.raw.x{t}(:,2),'k+','MarkerSize',10); 
        end

        drawnow
%         mov = addframe(mov,hfig);
        fprintf(1,'[t=%03d] ny=%d\n',t,size(gvs.sw.raw.sy{t},1));
        pause(.1);
    end
end
% mov = close(mov);

% for display
gvs.disp.winsize = tr.gvs.TMAX;

save(swobsfile,'gvs');
 
