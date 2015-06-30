function monitorCollectDataWaitEvent
global experiment
global ReportMsgHeard
global MONITOR_DATA

if isfield(MONITOR_DATA, 'rxArray') & all(MONITOR_DATA.rxArray(experiment.nodes(experiment.index),:))
   experiment.index = experiment.index + 1;
end

if experiment.index <= length(experiment.nodes)
   ReportMsgHeard = 0;
   monitorRunCollectData;
elseif experiment.reportChoice == 1
   disp('Phase 2 Done');

   stop(experiment.t);
   experiment.reportChoice = 2;
   MONITOR_DATA.rxArray=[];
   experiment.index=1;
   ReportMsgHeard = 0;

   disp('Phase 3 Starting');
   monitorRunCollectData;
elseif experiment.reportChoice == 2
   disp('Phase 3 Done');
    
   stop(experiment.t);
   experiment.reportChoice = 3;
   MONITOR_DATA.rxArray=[];
   experiment.index=1;
   ReportMsgHeard = 0;
    
   disp('Phase 4 Starting');
   monitorRunCollectData;    
    
else
   disp('Phase 4 Done');
   stop(experiment.t);
   save MONITOR_DATA MONITOR_DATA;
end





