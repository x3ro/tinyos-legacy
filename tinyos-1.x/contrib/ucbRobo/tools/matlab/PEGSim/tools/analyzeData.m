%analyzeData
% Script to analyze data generated over many runs


for i = 1:5
    for j = 1:20
        fName = sprintf('results/CovGammaTraj_50_25x25_%d_%d',j,i);
        load(fName);
        Tcov(i,j) = T;
        if Pctrlr.uninit %never received any packets
            runCov(i,j) = 0;
        else
            runCov(i,j) = 1;
        end
        
        fName = sprintf('results/BasicTraj_50_25x25_%d_%d',j,i);
        load(fName);
        Tbasic(i,j) = T;
        if Pctrlr.uninit %never received any packets
            runBasic(i,j) = 0;
        else
            runBasic(i,j) = 1;
        end
    end
end
