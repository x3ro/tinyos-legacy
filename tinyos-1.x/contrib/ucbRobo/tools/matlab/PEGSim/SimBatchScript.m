%SimBatchScript

global P;
global E;
global Eprecomp;
global T;
global history;
global Pctrlr;
global ReSimFlag;


t0 = clock;
%PEGSimMain('examples/scen21_25x25_fixedSN','examples/scen21_25x25_fixedPE');


% for i = 1:2
%     for j = 1:20
%         ReSimFlag = 0;
%         PEfile = sprintf('examples/PE100x100_%d',i);
%         SNfile = sprintf('examples/nodes400_100x100_%d',j);
%         PEGSimMain(SNfile,PEfile,'examples/Pctrlr_CovGamma_1');
%         fName = sprintf('results/CovGammaTraj_400_100x100_%d_%d',j,i);
%         save(fName,'P','E','T','history','Pctrlr');
% 
%         Eprecomp = E;
%         clearStates(1);
%         ReSimFlag = 1;
%         PEGSimMain(0,0,'examples/Pctrlr_Basic_1');
%         fName = sprintf('results/BasicTraj_400_100x100_%d_%d',j,i);
%         save(fName,'P','E','T','history','Pctrlr');
%     end
%end

%genSNScript
%genPEScript

% for i = 1:5
%     for j = 1:20
%         ReSimFlag = 0;
%         PEfile = sprintf('examples/PE25x25_%d',i);
%         SNfile = sprintf('examples/nodes50_25x25_%d',j);
%         PEGSimMain(SNfile,PEfile,'examples/Pctrlr_CovGamma_2');
%         fName = sprintf('results/CovGammaTraj_50_25x25_%d_%d',j,i);
%         save(fName,'P','E','T','history','Pctrlr');
% 
%         Eprecomp = E;
%         clearStates(1);
%         ReSimFlag = 1;
%         PEGSimMain(0,0,'examples/Pctrlr_Basic_1');
%         fName = sprintf('results/BasicTraj_50_25x25_%d_%d',j,i);
%         save(fName,'P','E','T','history','Pctrlr');
%     end
% end

for i = 1:5
    for j = 1:20
        ReSimFlag = 0;
        PEfile = sprintf('examples/PE50x50_%d',i);
        SNfile = sprintf('examples/nodes100_50x50_%d',j);
        Pctrlr.gWt = 1000; % to see differences
        PEGSimMain(SNfile,PEfile,'examples/Pctrlr_CovGamma_2');
        fName = sprintf('results/CovGammaTraj_100_50x50_%d_%d',j,i);
        save(fName,'P','E','T','history','Pctrlr');

        Eprecomp = E;
        clearStates(1);
        ReSimFlag = 1;
        PEGSimMain(0,0,'examples/Pctrlr_Basic_1');
        fName = sprintf('results/BasicTraj_100_50x50_%d_%d',j,i);
        save(fName,'P','E','T','history','Pctrlr');
    end
end




disp(sprintf('%.2f seconds to run Batch Simulation',etime(clock,t0)));


%% USAGE NOTES:
% * Consider calling clearStates before calling PEGSimMain(0,0,0)
%   if resimulating and not reloading data structures