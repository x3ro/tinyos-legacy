function monitorCollectDataTimerEvent
global experiment
global ReportMsgHeard

if ReportMsgHeard == 0
  disp('Heard NO Report Message');
  monitorRunCollectData;
else
  disp('Start collect data wait timer');
  if experiment.reportCommand == 0
    delay = 10;
  else
    delay = 1;
  end
  stop(experiment.t);
  set(experiment.t, 'TimerFcn', 'monitorCollectDataWaitEvent', 'StartDelay', delay, 'Period', delay, 'ExecutionMode', 'fixedRate');
  start(experiment.t);
end




