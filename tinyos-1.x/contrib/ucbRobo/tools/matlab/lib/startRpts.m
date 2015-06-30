function startRpts(appName)
% startRpts(appName)
% Sets the 'rptMsgFlag' field of all applications under the APPS
% structure to true if no arguments are given.  Otherwise, turns on
% the rptMsgFlag of the application whose field name under APPS is
% specified by the string 'appName'.
% 
% Usage: startRpts
%        startRpts('MAGLIGHT')
  
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
    APPS.(appNames{i}).rptMsgFlag = true;
end

