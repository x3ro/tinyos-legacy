 
function mondograph(basedir, pairs, stds)
maxhops = 2;
maxval = 10;
bytetime = .416; % confirmed by joe. 
f1 = figure;
for mode = 1:3
    switch mode
        case 1
            d='tsruns-ae';
            draw='r.-.'; 
        case 2
            d='tsruns-auth';
            draw='g*-';
        case 3
            d='tsruns-crc';
            draw='b+--';
    end
    data = [];
    for f=1:length(pairs)
        try
            cd(basedir);
            cd(d);
            hops = pairs(f,1);
            pdata=load(sprintf('Experiment_hops_%d_from_%d_to_%d.txt',hops, ...
                pairs(f,2), pairs(f,3)));
            maxhops=max(maxhops,hops);
        catch  
            continue;    
        end
        pdata= [ ones(size(pdata,1),1) * hops pdata];
        data = [data ; pdata];
    end
    ave = [];
    for i=1:15 
        if size(data,1) == 0 continue; end;
        t = data( data(:,1) == i, 3);
        if (length(t) == 0) continue; end;        
        m = mean(t);
        s = std(t);
        t = t(  (t < (m + stds * s)));
        ave(i,1) = i;
        ave(i,2) = mean(t);
    end
    if (mode >= 2) hold on; end
    len = size(ave,1);
    if len ~= 0
        disp(d);
        ave = ave(ave(:,1)>0,:);
        perave = ave;
        perave(:,2) = ave(:,2) ./ ((ave(:,1) + 2));
        switch mode
            case 1
                peraveae = perave;
            case 2
                peraveauth = perave;
            case 3
                peravecrc = perave;
        end
        maxval=max(maxval, max(ave(:,2)));
        plot (ave(:,1)+2, ave(:,2), draw);
    end
    hold off;
end
%axis([2 maxhops 0 ceil(maxval/50) * 50])
set(gca, 'XTick', 4:maxhops+2);
ylabel('Route time (ms)');
xlabel('Number of hops');
legend('TinySec: authentication and encryption','TinySec: authentication only', 'No security',4)

cd(basedir)
print(f1, '-depsc2', 'latency.eps')

f2 = figure;
peraveauth ;
peravecrc;
meanauthcrc =(mean(peraveauth(:,2)) - mean(peravecrc(:,2)))/bytetime;
meanaecrc   =(mean(peraveae(:,2)) - mean(peravecrc(:,2))) /bytetime;
meanaeauth  = (mean(peraveae(:,2)) - mean(peraveauth(:,2))) /bytetime;

plot(peraveae(:,1)+2,  (peraveae (:,2) - peravecrc(:,2))/bytetime, 'r+-.');
hold on
plot(peraveauth(:,1) +2, (peraveauth(:,2) - peravecrc(:,2))/bytetime, 'g*-');
plot(peraveauth(:,1)+2,meanauthcrc * ones(size(peraveauth,1)), 'g:');
plot(peraveae(:,1)+2, meanaecrc * ones(size(peraveae,1)), 'r:');
hold off
legend('Authentication and encryption', 'Authentication');
ylabel('Extra latency over no security in byte times')
xlabel('Number of hops');  
axis([4 12 -1  9])

%figure
%plot(peraveae(:,1),  (peraveae (:,2) - peraveauth(:,2))/bytetime, 'b+--');
%legend('ae vs auth')
%ylabel('Computed byte overhead (bytes)')
%xlabel('Number of hops');   

disp(sprintf('byte time diff, auth-crc: %f', meanauthcrc))
disp(sprintf('byte time diff, ae-crc: %f', meanaecrc))
disp(sprintf('byte time diff, ae-auth: %f', meanaeauth ))

print(f2, '-depsc2', 'bytediff.eps');