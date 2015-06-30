function rawScriptExec(obj,event,navCmdArgs)
% rawScriptExec(navCmdArgs)
%
% DOES NOT WORK.  Probably can't use pause in a timer called function.
% Function that is meant to be called by a timer to execute a script.  Not
% meant to be called by the user directly.  This is to allow for "multiple
% threads'.
%
% Usage: timer('TimerFcn',{'rawScriptExec', navCmdArgs}, 'StartDelay', 0);
% 
% navCmdArgs [[turn speed time moteID] ...]

for i=1:size(navCmdArgs,1)
    a = navCmdArgs(i,:)
    turnRaw(a(1),a(2),a(3),a(4));
    pause(a(3));
end