function peepRpts(appName)
% peepRpts(appName)
% takes a quick look (1 second) to see if we are receiving messages from
% the named application.
%
% This is useful if there are a lot of messages being reported, and you
% don't want to flood MATLAB's screen for too long.  This operates by
% setting the 'appName'.rptMsgFlag to true for a short period of time,
% and then restoring it to its previous value.  It calls a helper function
% in another file (a MATLAB hack... read peepRpts_helper for more details)
% to restore the rptMsgFlag.
%
% Usage: peepRpts
%        peepRpts('MAGLIGHT')

global APPS;
global peepRpts_flagArr;
global peepRpts_appNames; 
persistent t; %so we don't have a billion timers over time


if isempty(APPS)
    disp('no applications running');
    return;
end

if isempty(t)
    t = timer('TimerFcn','peepRpts_helper','StartDelay',1);
end
     
if strcmp(t.Running,'on')
    disp('hold on, your old peepRpts is still running');
    return;
end

if (nargin < 1)
    peepRpts_appNames = fieldnames(APPS);
else
    if isField(APPS,appName)
        peepRpts_appNames = {appName}
    else
        disp(sprintf('no such application in APPS: %d', appName));
    end
end


% The real work....

for i = 1:length(peepRpts_appNames)
    peepRpts_flagArr(i) = APPS.(peepRpts_appNames{i}).rptMsgFlag;
    APPS.(peepRpts_appNames{i}).rptMsgFlag = true;
end

start(t);
