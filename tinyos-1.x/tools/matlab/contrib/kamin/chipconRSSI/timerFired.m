function timerFired
%function timerFired
%
%this function will handle the timer event and change states as follows:
%
% transmitter=0;
% state=START_CHIRPING;
% period=MEDIUM;
%If state==START_CHIRPING
%   -> transmitter=transmitter+1;
%   -> if(transmitter>length(transmitters))
%       stop timer;
%   -> else
%       tell the transmitter to start chirping
%       numTries=1;
%       STATE=TRYING_TO_CHIRP
%If state==TRYING_TO_CHIRP
%   -> if numTries>MAX_TRIES
%       disp('transmitter x not responding, press to continue')
%       timer.stop
%       pause
%   -> if no chirps received
%       tell the transmitter to start chirping
%       numTries++;
%   -> else 
%       set state to CHIRPING
%       change period to LONG
%If state==CHIRPING
%   -> set state to START_COLLECTING
%   -> receiver=0;
%   -> change period to MEDIUM
%If state==START_COLLECTING
%   -> if(transmitters(transmitter)==receivers(receiver+1))
%       receiver=receiver+2;
%   -> else
%       receiver=receiver+1;
%   -> if(receiver>length(receivers))
%       state=START_CHIRPING;
%   -> else
%       tell the receiver to transmit all rssi data
%       numTries=1;
%       STATE=TRYING_TO_COLLECT
%If state==TRYING_TO_COLLECT
%   -> if numTries>MAX_TRIES
%       disp('receiver x not responding, 1 to continue, 2 to abort')
%       timer.stop
%       if continue
%           timer.start
%       else
%          state=START_COLLECTING
%   -> if no RSSI received
%       tell the receiver to send all rssi data
%       numTries++;
%   -> else 
%       set state to COLLECTING
%       numTries=0;
%       change period to LONG
%If state==COLLECTING
%   -> if numTries>MAX_INDIVIDUAL_TRIES
%       disp('receiver x not responding, 1 to continue, 2 to abort')
%       timer.stop
%       if continue
%           timer.start
%       else
%          state=START_COLLECTING
%   -> change period to SHORT
%   -> if collected all rssi
%   -> change period to MEDIUM
%       state=START_COLLECTING
%   -> else
%       find missing message index
%       ask receiver for message index
%       numTries++;


global CHIPCON
global mIF

switch CHIPCON.state
    case CHIPCON.SET_RF_POWER
        CHIPCON.rfPower=CHIPCON.rfPower+1;
        if(CHIPCON.rfPower>length(CHIPCON.rfPowers))
          stop(CHIPCON.timer); %done
          disp('done')
%          CHIPCON.RSSI
        else
          CHIPCON.chirpCommandMsg.set_rfPower(CHIPCON.rfPowers(CHIPCON.rfPower));%set the rf power in the packet      
          CHIPCON.state=CHIPCON.START_CHIRPING;
          disp(['RF Power set to ' num2str(CHIPCON.rfPowers(CHIPCON.rfPower))])
        end

    case CHIPCON.START_CHIRPING
       CHIPCON.transmitter=CHIPCON.transmitter+1;
        if(CHIPCON.transmitter>length(CHIPCON.transmitters))
%          stop(CHIPCON.timer); %done
          CHIPCON.state =CHIPCON.START_COLLECTING;
          CHIPCON.receiver=0;
        else
          CHIPCON.numTries=0;
          CHIPCON.numChirpsReceived=0;
          CHIPCON.state=CHIPCON.TRYING_TO_CHIRP;
          disp(['Transmitter ' num2str(CHIPCON.transmitters(CHIPCON.transmitter)) ' to chirp.'])
        end

   case CHIPCON.TRYING_TO_CHIRP
      if CHIPCON.numChirpsReceived==0
           if CHIPCON.numTries>CHIPCON.MAX_TRIES
              stop(CHIPCON.timer)
	%          command=input(['transmitter ' int2str(CHIPCON.transmitters(CHIPCON.transmitter)) ' not responding: press 1 to continue, 2 to abort: ']);
              command=2;
              if command==2
                  CHIPCON.state=CHIPCON.START_CHIRPING;
                  start(CHIPCON.timer);
                  return
              end
              CHIPCON.numTries=0;
              start(CHIPCON.timer);
          elseif CHIPCON.numTries>7
              beep
          end
          CHIPCON.chirpCommandMsg.set_transmitterId(CHIPCON.transmitters(CHIPCON.transmitter));
          CHIPCON.mIF(1).send(CHIPCON.BROADCAST, CHIPCON.chirpCommandMsg);
          CHIPCON.numTries=CHIPCON.numTries+1;
          disp(['Commanded transmitter ' num2str(CHIPCON.transmitters(CHIPCON.transmitter)) ' to chirp ****'])
      else 
          CHIPCON.state =CHIPCON.CHIRPING;
          stop(CHIPCON.timer)
%          pause(CHIPCON.LONG) %%this is used instead to prevent the timer overflow problem
          CHIPCON.timer.Period=CHIPCON.LONG;
          CHIPCON.timer.StartDelay=CHIPCON.LONG;
          start(CHIPCON.timer);
          disp(['Transmitter ' num2str(CHIPCON.transmitters(CHIPCON.transmitter)) ' is chirping.'])
      end

	case CHIPCON.CHIRPING
      stop(CHIPCON.timer)
      CHIPCON.timer.Period=CHIPCON.SHORT;
      CHIPCON.timer.StartDelay=CHIPCON.SHORT;
      start(CHIPCON.timer);
      if CHIPCON.oldNumChirpsReceived==CHIPCON.numChirpsReceived
          CHIPCON.oldNumChirpsReceived=0;
          CHIPCON.state =CHIPCON.START_CHIRPING;
	%       CHIPCON.state =CHIPCON.START_COLLECTING;
	%       CHIPCON.receiver=0;
          disp(['Transmitter ' num2str(CHIPCON.transmitters(CHIPCON.transmitter)) ' done chirping.'])
      else
          CHIPCON.oldNumChirpsReceived=CHIPCON.numChirpsReceived;
      end
          
	case CHIPCON.START_COLLECTING
      CHIPCON.receiver=CHIPCON.receiver+1;
      if(CHIPCON.receiver>length(CHIPCON.receivers))
%            stop(CHIPCON.timer) %done
          Rssi=CHIPCON.RSSI;
          save CHIPCONRssi.mat Rssi
          CHIPCON.state=CHIPCON.SET_RF_POWER;
          CHIPCON.transmitter=0;
          stop(CHIPCON.timer)
          CHIPCON.timer.Period=CHIPCON.SHORT;
          CHIPCON.timer.StartDelay=0;
          start(CHIPCON.timer);
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
      elseif CHIPCON.overview(CHIPCON.receiver)==0
          CHIPCON.state=CHIPCON.START_COLLECTING; %if this node didn't hear anything, skip it
          disp(['Receiver ' num2str(CHIPCON.receivers(CHIPCON.receiver)) '''s overview contains 0 msgs.'])
      else          
          CHIPCON.state =CHIPCON.TRYING_TO_COLLECT;
          CHIPCON.numTries=0;
          CHIPCON.numRSSIMsgsReceived=0;
    	  CHIPCON.collectionStartNum = 0;
          disp(['Got Receiver ' num2str(CHIPCON.receivers(CHIPCON.receiver)) '''s overview.'])
          stop(CHIPCON.timer)
          CHIPCON.timer.Period=CHIPCON.MEDIUM;
          CHIPCON.timer.StartDelay=0;
          start(CHIPCON.timer);
      end
      
  case CHIPCON.TRYING_TO_COLLECT
      if CHIPCON.numRSSIMsgsReceived==0
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
          CHIPCON.dataRequestMsg.set_typeOfData(1);
          CHIPCON.dataRequestMsg.set_msgIndex(CHIPCON.collectionStartNum);
          CHIPCON.mIF(1).send(CHIPCON.receivers(CHIPCON.receiver), CHIPCON.dataRequestMsg);
          CHIPCON.numTries=CHIPCON.numTries+1;
          disp(['Tried to get Receiver ' num2str(CHIPCON.receivers(CHIPCON.receiver)) '''s rssi data starting at ' num2str(CHIPCON.collectionStartNum) ' ****'])
      else 
          CHIPCON.state =CHIPCON.COLLECTING;
          CHIPCON.numTries=0;
          stop(CHIPCON.timer)
%          pause(max(0,(CHIPCON.overview(CHIPCON.receiver)-CHIPCON.collectionStartNum)/(650/(CHIPCON.PERIOD)))); %this is done to prevent the java memory errors
          CHIPCON.timer.Period=CHIPCON.SHORT;
          CHIPCON.timer.StartDelay=max(0,(CHIPCON.overview(CHIPCON.receiver)-CHIPCON.collectionStartNum)/(650/(CHIPCON.PERIOD)));
          start(CHIPCON.timer);
          disp(['Getting Receiver ' num2str(CHIPCON.receivers(CHIPCON.receiver)) '''s rssi Data.'])
      end
      
      
  case CHIPCON.COLLECTING
   stop(CHIPCON.timer)
   CHIPCON.timer.Period=CHIPCON.SHORT;
   CHIPCON.timer.StartDelay=CHIPCON.SHORT;
   start(CHIPCON.timer);
   rxd=sort(CHIPCON.RSSI(find(CHIPCON.RSSI(:,1)==CHIPCON.receivers(CHIPCON.receiver) & CHIPCON.RSSI(:,4)==CHIPCON.rfPowers(CHIPCON.rfPower) ), 3));
   if length(rxd) < CHIPCON.overview(CHIPCON.receiver)
      notRxd = setdiff([0:CHIPCON.overview(CHIPCON.receiver)-1], rxd);
%      if isempty(intersect([notRxd(1):CHIPCON.overview(CHIPCON.receiver)-1], rxd))
%           CHIPCON.state =CHIPCON.TRYING_TO_COLLECT;
%           CHIPCON.numTries=0;
%           CHIPCON.numRSSIMsgsReceived=0;
% 	  CHIPCON.collectionStartNum = notRxd(1);
%           disp(['Got Receiver ' num2str(CHIPCON.receivers(CHIPCON.receiver)) '''s overview.'])
%           stop(CHIPCON.timer)
%           CHIPCON.timer.Period=CHIPCON.MEDIUM;
%           CHIPCON.timer.StartDelay=0;
%           start(CHIPCON.timer);
%      else
       CHIPCON.dataRequestMsg.set_typeOfData(2);
       CHIPCON.dataRequestMsg.set_msgIndex(notRxd(1));
       CHIPCON.mIF(1).send(CHIPCON.receivers(CHIPCON.receiver), CHIPCON.dataRequestMsg);
       disp(['Asking again for missing data: Receiver ' num2str(CHIPCON.receivers(CHIPCON.receiver)) '''s packet #' num2str(notRxd(1))])
%      end
   else
     CHIPCON.state=CHIPCON.START_COLLECTING;
   end          
%       
%   case CHIPCON.COLLECTING
%       if CHIPCON.numTries>CHIPCON.MAX_INDIVIDUAL_TRIES
%           stop(CHIPCON.timer)
% %          command=input(['receiver ' int2str(CHIPCON.receivers(CHIPCON.receiver)) ' not responding: press 1 to continue, 2 to abort: ']);
%           command=2;
%           if command==2
%               CHIPCON.state=CHIPCON.START_COLLECTING;
%               start(CHIPCON.timer);
%               return
%           end
%           CHIPCON.numTries=0;
%           start(CHIPCON.timer);
%       end
%       stop(CHIPCON.timer)
%       CHIPCON.timer.Period=CHIPCON.SHORT;
%       CHIPCON.timer.StartDelay=CHIPCON.SHORT;
%       start(CHIPCON.timer);
%       trans=CHIPCON.RSSI(find(CHIPCON.RSSI(:,2)==CHIPCON.transmitters(CHIPCON.transmitter)), :);
%       transrec=trans(find(trans(:,1)==CHIPCON.receivers(CHIPCON.receiver)), :);
%       if size(transrec,1)==CHIPCON.overview(CHIPCON.receiver, CHIPCON.transmitter)
%           stop(CHIPCON.timer)
%           CHIPCON.timer.Period=CHIPCON.SHORT;
%           CHIPCON.timer.StartDelay=CHIPCON.SHORT;
%           start(CHIPCON.timer);
%           CHIPCON.state=CHIPCON.START_COLLECTING;
%       else
%           msgIndexes = sort(transrec(:,4));
%           if isempty(transrec) | msgIndexes(1)~=0
%               missingIndex=0;
%           else
%               temp=find(diff(msgIndexes)>1);
%               if ~isempty(temp)
%                   missingIndex=temp(1)+1;
%               else
%                   missingIndex=CHIPCON.overview(CHIPCON.receiver, CHIPCON.transmitter);
%               end
%           end
%           CHIPCON.dataRequestMsg.set_typeOfData(2);
%           CHIPCON.dataRequestMsg.set_msgIndex(missingIndex);
%           CHIPCON.mIF(1).send(CHIPCON.receivers(CHIPCON.receiver), CHIPCON.dataRequestMsg);
%           CHIPCON.numTries=CHIPCON.numTries+1;
%           disp(['Getting Receiver ' num2str(CHIPCON.receiver) '''s ' num2str(missingIndex) 'th rssi Data.'])
%       end
end
