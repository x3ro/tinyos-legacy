function monitorRunCollectData
global experiment
global MONITOR_DATA



if ~isfield(MONITOR_DATA, 'rxArray') | size(MONITOR_DATA.rxArray,1)<experiment.nodes(experiment.index) |  ~any(MONITOR_DATA.rxArray(experiment.nodes(experiment.index),:))
	experiment.reportCommand = 0;
else
    tmp = find(MONITOR_DATA.rxArray(experiment.nodes(experiment.index),:)==0);
    experiment.reportCommand = tmp(1);
end

feval('peg', experiment.nodes(experiment.index), 'CalamariMonitorReport', experiment.reportCommand, experiment.reportChoice);

% start a timer
disp('Starting Collect Data timer');
delay = 1; %sec
stop(experiment.t);
set(experiment.t, 'TimerFcn', 'monitorCollectDataTimerEvent', 'StartDelay', delay, 'Period', delay, 'ExecutionMode', 'fixedRate');
start(experiment.t);
