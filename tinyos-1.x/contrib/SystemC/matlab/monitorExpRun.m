function monitorExpRun
global experiment
global isChirpMsgHeard

rangeID = sprintf('MyRangingId(%d)', experiment.nodes(experiment.index));
feval('peg', experiment.nodes(experiment.index), rangeID);

isChirpMsgHeard = 0;

% Assume nodes(i) is decimal
feval('peg',experiment.nodes(experiment.index), 'CalamariRangeOnce');

% start a timer
disp('Starting Timeout timer');
monitorTimerExpired = 0;
delay = 1; %sec

if ~isfield(experiment,'t')
  experiment.t = timer;
end
stop(experiment.t);
set(experiment.t, 'TimerFcn', 'monitorTimerEvent', 'StartDelay', delay, 'Period', delay, 'ExecutionMode', 'fixedRate');
start(experiment.t);
