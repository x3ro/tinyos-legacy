function startLogging(appName)
% startLogging(appName)
% Sets the 'logMsgFlag' field of all applications under the APPS
% structure to true if no arguments are given.  Otherwise, turns on
% the logMsgFlag of the application whose field name under APPS is
% specified by the string 'appName'.
% 
% Usage: startLogging
%        startLogging('MAGLIGHT')
  
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
    APPS.(appNames{i}).logMsgFlag = true;
end

