function stopOnlineTracking
% stopOnlineTracking (no arguments)
% Stops the periodic timer event that runs the online tracking algorithm.
% See Also: 'startOnlineTracking'

global MTT; %multi-target tracking run-online variables

if isempty(MTT)
    error('no MTT: perhaps not started?');
end

stop(MTT.timer);
delete(MTT.timer);
MTT.running = false;