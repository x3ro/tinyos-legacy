function initializeChipconRSSI(varargin)
%initializeChipconRSSI()
%

import net.tinyos.*
import net.tinyos.message.*
import net.tinyos.chipconRSSI.*
if length(varargin)<4 varargin{4}=1; end %by default, rf power is set to smallest possible

global CHIPCON

CHIPCON.transmitters=varargin{1};
CHIPCON.receivers=varargin{2};
CHIPCON.mIF=varargin{3};
CHIPCON.rfPowers=varargin{4};

CHIPCON.SET_RF_POWER=8;
CHIPCON.START_CHIRPING=1;
CHIPCON.TRYING_TO_CHIRP=2;
CHIPCON.CHIRPING=3;
CHIPCON.START_COLLECTING=4;
CHIPCON.TRYING_TO_COLLECT_OVERVIEW=5;
CHIPCON.TRYING_TO_COLLECT=6;
CHIPCON.COLLECTING=7;

CHIPCON.SAVE_TO_EEPROM=0;
CHIPCON.BROADCAST=65535;

CHIPCON.NUMBER_OF_CHIRPS=5; 
CHIPCON.PERIOD=75;%milliseconds
CHIPCON.SHORT=.2;
CHIPCON.MEDIUM=.4;
CHIPCON.LONG=CHIPCON.NUMBER_OF_CHIRPS/(650/(CHIPCON.PERIOD));
CHIPCON.REALLY_LONG=length(CHIPCON.transmitters)*3/(650/(CHIPCON.PERIOD));

CHIPCON.numTries=0;
CHIPCON.MAX_TRIES=50;
CHIPCON.MAX_INDIVIDUAL_TRIES=CHIPCON.NUMBER_OF_CHIRPS/5;

bCHIPCON.chirpMsg = chipconRSSI.ChirpMsg;
CHIPCON.dataMsg = chipconRSSI.DataMsg;
CHIPCON.dataOverviewMsg = chipconRSSI.DataOverviewMsg;

CHIPCON.chirpCommandMsg = chipconRSSI.ChirpCommandMsg;
CHIPCON.chirpCommandMsg.set_startStop(1);
CHIPCON.chirpCommandMsg.set_transmitterId(2);
CHIPCON.chirpCommandMsg.set_numberOfChirps(CHIPCON.NUMBER_OF_CHIRPS);
CHIPCON.chirpCommandMsg.set_timerPeriod(400);
CHIPCON.chirpCommandMsg.set_receiverAction(CHIPCON.SAVE_TO_EEPROM);%save to eeprom
CHIPCON.chirpCommandMsg.set_rfPower(CHIPCON.rfPowers(1));%save to eeprom

CHIPCON.dataOverviewRequestMsg = chipconRSSI.DataRequestMsg;
CHIPCON.dataOverviewRequestMsg.set_startStop(1);
CHIPCON.dataOverviewRequestMsg.set_typeOfData(0);
CHIPCON.dataOverviewRequestMsg.set_msgIndex(0);
CHIPCON.dataOverviewRequestMsg.set_timerPeriod(400);
CHIPCON.dataOverviewRequestMsg.set_receiverAction(CHIPCON.BROADCAST);

CHIPCON.dataRequestMsg = chipconRSSI.DataRequestMsg;
CHIPCON.dataRequestMsg.set_startStop(1);
CHIPCON.dataRequestMsg.set_typeOfData(1);
CHIPCON.dataRequestMsg.set_msgIndex(0);
CHIPCON.dataRequestMsg.set_timerPeriod(400);
CHIPCON.dataRequestMsg.set_receiverAction(65535);

CHIPCON.state=CHIPCON.SET_RF_POWER;
CHIPCON.transmitter=0;
CHIPCON.numChirpsReceived=0;
CHIPCON.collectionStartNum=0;
CHIPCON.oldNumChirpsReceived=0;
CHIPCON.receiver=0;
CHIPCON.numRSSIMsgsReceived=0;
CHIPCON.overviewReceived=0;
CHIPCON.rfPower=0;

%format of position matrix:
%nodeID Xcm Ycm Zcm
CHIPCON.positions=[
    1   0   0   0;
    2   0   0   0;
    3   0   0   0;
    4   0   0   0;
    5   0   0   0;
    6   0   0   0;
    7   0   0   0;
    8   0   0   0;
    9   0   0   0;
    10   0   0   0;
    11   0   0   0;
    12   0   0   0;
    13   0   0   0;
    14   0   0   0;
    15   0   0   0;
    16   0   0   0;
];

%format of overview matrix:
%overview(receiver,transmitter)= numMsgs received
CHIPCON.overview=-ones(1, length(CHIPCON.receivers));


%format of RSSI matrix:
%receiver transmitter msgNumber msgIndex RSSI_1  RSSI_2  RSSI_3  RSSI_4  RSSI_5 RSSI_6  RSSI_7  RSSI_8  RSSI_9  RSSI_10
CHIPCON.RSSI=zeros(1,15);
CHIPCON.rssiLength=1;

if ~isfield(CHIPCON,'timer') | isempty(CHIPCON.timer)
    CHIPCON.timer = timer('TimerFcn', 'timerFired', 'Period', CHIPCON.SHORT, 'Name', 'RSSI Timer','ExecutionMode','fixedRate');
    %start(CHIPCON.timer) %use the "play" button on the gui to start the timer
end
set(CHIPCON.timer, 'TimerFcn','timerFired')
set(CHIPCON.timer, 'Period',CHIPCON.SHORT)
set(CHIPCON.timer, 'ErrorFcn','restartTimer')

% CHIPCON.transmitter=0;
% CHIPCON.state=CHIPCON.START_CHIRPING;
% stop(CHIPCON.timer)
% CHIPCON.timer.period=CHIPCON.MEDIUM;
% start(CHIPCON.timer);
