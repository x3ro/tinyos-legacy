function runlocalization(experimentName,experimentNumber)
%pass a parameter when starting
%
%this function will run an entire localization run

global TESTBED

if ~isfield(TESTBED,'runTimer') | isempty(TESTBED.runTimer)
    TESTBED.runTimer=timer('Name','Run Timer','TimerFcn', 'runlocalization');
end
if nargin>=1 %the user is calling me
  if nargin<2 | isempty(experimentNumber) | experimentNumber==TESTBED.experimentNumber
    disp('WARNING: you didn''t change the experimentNumber!!!!!!!!!')
  end
  TESTBED.experimentNumber=experimentNumber;

  TESTBED.experimentName=experimentName;
  stop(TESTBED.runTimer) %in case it was running
  set(TESTBED.runTimer, 'Name','Run Timer','TimerFcn', 'runlocalization', 'StartDelay', 0, 'Period', 5, 'ExecutionMode', 'fixedRate','BusyMode','drop');
  pegstart
  TESTBED.runState='init';
  TESTBED.readyToChangeState=0;
  TESTBED.msgsReceived=0;
  TESTBED.round=1;
  disp('hit PLAY button when ready')
%    start(TESTBED.runTimer) 

else%called by timer starts here

  if strcmp(TESTBED.runState,'ident') %if I am in 'ident' see if ready to move on
    if all(TESTBED.identReported)
      TESTBED.readyToChangeState=0;
    end
  elseif strcmp(TESTBED.runState,'calamariRanging') %if I am in 'ident' see if ready to move on
    if TESTBED.msgsReceived>0 %heard from most recent guy
      TESTBED.msgsReceived=0;
      TESTBED.readyToChangeState=100; 
    elseif TESTBED.readyToChangeState==100 %heard from most recent guy and he has since stopped
      TESTBED.readyToChangeState=5;
      TESTBED.transmitter=TESTBED.transmitter+1;
      while TESTBED.transmitter<length(TESTBED.nodeIDs) & any(TESTBED.nodeIDs(TESTBED.transmitter)==TESTBED.deadNodes)
	TESTBED.transmitter=TESTBED.transmitter+1;
      end
      if TESTBED.transmitter>length(TESTBED.nodeIDs) %finished last guy
	TESTBED.readyToChangeState=0;
	return
      else
	disp(['peg ' num2str(TESTBED.nodeIDs(TESTBED.transmitter)) ' CalamariRangeOnce'])
	eval(['peg ' num2str(TESTBED.nodeIDs(TESTBED.transmitter)) ' CalamariRangeOnce']);
      end
    elseif TESTBED.readyToChangeState==5 %haven't heard from this guy yet so try to make him chirp
      disp(['peg ' num2str(TESTBED.nodeIDs(TESTBED.transmitter)) ' CalamariRangeOnce'])
      eval(['peg ' num2str(TESTBED.nodeIDs(TESTBED.transmitter)) ' CalamariRangeOnce']);      
    end      
  elseif strcmp(TESTBED.runState,'getRanging') %if I am in 'ident' see if ready to move on
    if all(TESTBED.rangingReported)
      TESTBED.readyToChangeState=0;
    end
  elseif strcmp(TESTBED.runState,'setLocations') %if I am in 'ident' see if ready to move on
    %don't change state here
  elseif strcmp(TESTBED.runState,'report') %if I am in 'ident' see if ready to move on
    if all(TESTBED.rangingReported) & all(TESTBED.anchorsReported) & all(TESTBED.locationReported)
      TESTBED.readyToChangeState=0;
    end
  else     %for all other states, must get a message before ready to change state (and also must not get msgs for 10 seconds)
    if TESTBED.msgsReceived>0  
      TESTBED.msgsReceived=0;
      TESTBED.readyToChangeState=TESTBED.readyToChangeState-1;
      return;
    end
  end
  
  if TESTBED.readyToChangeState<=0 %do the state change
      beep
      pause(.1)
      beep
      TESTBED.msgsReceived=0;
      TESTBED.readyToChangeState=5; %default num clock ticks to wait
    switch TESTBED.runState
     case 'init'
      TESTBED.runState='ident';
      getReport('ident')
      disp('getReport(''ident'')')
     case 'ident'
      TESTBED.runState='setLocations';
      setLocationInfo;
      TESTBED.readyToChangeState=0;
     case 'setLocations'
      TESTBED.runState='calamariRanging';
      TESTBED.transmitter=1;
      runlocalization
     case 'calamariRanging'
      for p=1:3
	disp('peg all txRetry(0)');
	peg all txRetry(0);
	pause(0.5)
      end
      TESTBED.runState='getRanging';
      disp('getReport(''ranging'')')
      getReport('ranging')
     case 'getRanging'
      for p=1:3
	disp('peg all txRetry(4)');
	peg all txRetry(4);
	pause(0.5)
      end
      TESTBED.runState='calamariShortestPath';
      TESTBED.readyToChangeState=1;
      disp('peg all CalamariShortestPath')
      eval('peg all CalamariShortestPath');
     case 'calamariShortestPath'  
      TESTBED.runState='calamariLocalization';
      TESTBED.readyToChangeState=0;
      disp('peg all CalamariLocalization')
      peg all CalamariLocalization;
      pause(5)
      disp('peg all CalamariLocalization')
      peg all CalamariLocalization;
      pause(5)
      disp('peg all CalamariLocalization')
      peg all CalamariLocalization;
      pause(5)
     case 'calamariLocalization'
      TESTBED.runState='reporting';
      for p=1:3
	disp('peg all txRetry(0)');
	peg all txRetry(0);
	pause(0.5)
      end
      disp('getReport({''ranging'',''rangingValues'',''anchors'',''location''})')
      getReport({'ranging','rangingValues','anchors','location'});
     case 'reporting'
      for p=1:3
	disp('peg all txRetry(4)');
	peg all txRetry(4);
	pause(0.5)
      end
      if TESTBED.round==1
	TESTBED.round=2;
	disp(['saving to: ' TESTBED.experimentName '_noExchange_exp' num2str(TESTBED.experimentNumber)])
	saveTESTBED([TESTBED.experimentName '_noExchange_exp' num2str(TESTBED.experimentNumber)])
	plotXY(TESTBED);
	figure(gcf);
	for i=1:TESTBED.retry*3
	  disp('peg all exchangeRanging(1)')
	  peg all exchangeRanging(1)
	  pause(.5)
	end
	TESTBED.runState='calamariRanging';
	TESTBED.readyToChangeState=0;
      elseif TESTBED.round==2
	stop(TESTBED.runTimer);
	TESTBED.runState='done';
	saveTESTBED([TESTBED.experimentName '_exp' num2str(TESTBED.experimentNumber)])
	disp('done localizing')
	plotXY(TESTBED);
	figure(gcf);
	beep
	pause(.1)
	beep
	pause(.1)
	beep
	pause(.1)
      end
    end
  end
end
