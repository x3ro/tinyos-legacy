function clearRssiDataBuffers(varargin)
global CHIPCON
global mIF

if nargin~=0
    CHIPCON.state=CHIPCON.START_COLLECTING;
    set(CHIPCON.timer, 'TimerFcn','clearRssiDataBuffers')
end
switch CHIPCON.state
	case CHIPCON.START_COLLECTING
      CHIPCON.receiver=CHIPCON.receiver+1;
      if(CHIPCON.receiver>length(CHIPCON.receivers))
          stop(CHIPCON.timer) %done
          disp('done')
      else 
%           if(CHIPCON.transmitters(CHIPCON.transmitter)==CHIPCON.receivers(CHIPCON.receiver))
%             CHIPCON.state=CHIPCON.START_COLLECTING; %skip this receiver
%           else
              CHIPCON.numTries=0;
              CHIPCON.overviewReceived=0;
              CHIPCON.state=CHIPCON.TRYING_TO_COLLECT_OVERVIEW;
              disp(['Receiver ' num2str(CHIPCON.receivers(CHIPCON.receiver)) ' to send RSSI.'])
%           end
      end    
      
    case CHIPCON.TRYING_TO_COLLECT_OVERVIEW
      if CHIPCON.overviewReceived==0
          if CHIPCON.numTries>CHIPCON.MAX_TRIES
              stop(CHIPCON.timer)
	%          command=input(['receiver ' int2str(CHIPCON.receivers(CHIPCON.receiver)) ' not responding: press 1 to continue, 2 to abort: ']);
              command=2;
              if command==2
                  CHIPCON.state=CHIPCON.START_COLLECTING;
                  start(CHIPCON.timer);
                  return
              end
              CHIPCON.numTries=0;
              start(CHIPCON.timer);
          elseif CHIPCON.numTries>7
              beep
          end
          CHIPCON.dataRequestMsg.set_typeOfData(0);
          CHIPCON.mIF(1).send(CHIPCON.receivers(CHIPCON.receiver), CHIPCON.dataRequestMsg);
          CHIPCON.numTries=CHIPCON.numTries+1;
          disp(['Tried to get Receiver ' num2str(CHIPCON.receivers(CHIPCON.receiver)) '''s overview ****.'])
      else          
          CHIPCON.state=CHIPCON.START_COLLECTING;
          CHIPCON.numTries=0;
          CHIPCON.overviewReceived=0;
          CHIPCON.numTries=0;
          CHIPCON.numRSSIMsgsReceived=0;
    	  CHIPCON.collectionStartNum = 0;
          disp(['Got Receiver ' num2str(CHIPCON.receivers(CHIPCON.receiver)) '''s overview.'])
          stop(CHIPCON.timer)
          CHIPCON.timer.Period=CHIPCON.MEDIUM;
          CHIPCON.timer.StartDelay=0;
          start(CHIPCON.timer);
      end
end