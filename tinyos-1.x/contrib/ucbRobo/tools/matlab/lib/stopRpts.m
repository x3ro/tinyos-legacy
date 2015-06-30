function stopRpts(appName)
% stopRpts(appName)
% Sets the 'rptMsgFlag' field of all applications under the APPS
% structure to false if no arguments are given.  Otherwise, turns off
% the rptMsgFlag of the application whose field name under APPS is
% specified by the string 'appName'.
% 
% Usage: stopRpts
%        stopRpts('MAGLIGHT')
  
global APPS;
if isempty(APPS)
    disp('no applications running');
    return;
end

if (nargin < 1)
    appNames = fieldnames(APPS);
else
    appNames = {appName}
end

for i = 1:length(appNames)
    APPS.(appNames{i}).rptMsgFlag = false;
end

