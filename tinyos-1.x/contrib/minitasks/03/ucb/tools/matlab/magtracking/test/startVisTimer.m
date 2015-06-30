function startVisTimer
% start a timer, to refresh the graphics

global VIS;

if ~isfield(VIS, 'timer') | isempty(VIS.timer)
  VIS.timer = timer('TimerFcn','drawVis', ...
                    'Period', .2, ...
                    'Name', 'Mag Tracking Refresh', ...
		    'BusyMode', 'drop', ...
                    'ExecutionMode','fixedRate');
end


start(VIS.timer);

