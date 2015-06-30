function fig(directory, hops, src, dst)
    oldpath=pwd;
    cd(directory);
    a=load(sprintf('Experiment_hops_%d_from_%d_to_%d.txt', hops, src, dst));
    cd(oldpath);
    acol = a(:,2);
    
    aclean=acol(find(acol < mean(acol) + 2 * std(acol)))
    figure 
    subplot(2,1,1), hist(acol);
   % axis([100 300 0 100])
    title(sprintf('%s %d --> %d || Mean %4.2f, std %4.2f', directory, src, dst,mean(acol), std(acol)))
    subplot(2,1,2), hist(aclean);
    %axis([100 300 0 100])
    title(sprintf('%s %d --> %d ||  Mean %4.2f, std %4.2f', directory, src, dst,mean(aclean), std(aclean)))
