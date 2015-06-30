function monitorWaitEvent
global experiment

experiment.index = experiment.index + 1;
if experiment.index <= length(experiment.nodes)
   monitorExpRun;
else
   disp('Done Phase 1');
   disp('Start Collecting Data');
   experiment.index = 1;
   experiment.reportChoice=1;
   monitorRunCollectData;
end





