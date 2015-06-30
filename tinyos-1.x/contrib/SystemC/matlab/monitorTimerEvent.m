function monitorTimerEvent
global experiment
global isChirpMsgHeard

if isChirpMsgHeard == 0
  disp('Heard NO Chirp Message');
  monitorExpRun;
else
  disp('Start wait timer');
  delay = 5;
  stop(experiment.t);
  set(experiment.t, 'TimerFcn', 'monitorWaitEvent', 'StartDelay', delay, 'Period', delay, 'ExecutionMode', 'fixedRate');
  start(experiment.t);

end




