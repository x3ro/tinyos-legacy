function stopPlots(appName)
% stopPlots(appName)
% Sets the 'plotMsgFlag' field of all applications under the APPS
% structure to false if no arguments are given.  Otherwise, turns off
% the plotMsgFlag of the application whose field name under APPS is
% specified by the string 'appName'.
% 
% Usage: stopPlots
%        stopPlots('MAGLIGHT')
  
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
    APPS.(appNames{i}).plotMsgFlag = false;
end

