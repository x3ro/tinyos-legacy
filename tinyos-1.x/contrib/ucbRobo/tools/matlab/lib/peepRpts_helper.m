function peepRpts_helper()
% Helper function called by timer in peepRpts.  Not meant to be called
% directly by the user. Restores the 'rptMsgFlag' setting of the applications.
%
% A separate file because MATLAB uses global namespace when executing
% timers... no lexical scoping apparently.

global peepRpts_flagArr;
global peepRpts_appNames; 
global APPS;
for i = 1:length(peepRpts_flagArr)
    APPS.(peepRpts_appNames{i}).rptMsgFlag = peepRpts_flagArr(i);
end
