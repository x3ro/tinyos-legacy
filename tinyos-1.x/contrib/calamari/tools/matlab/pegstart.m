function pegstart(addr, numtimes)
global TESTBED
if nargin<1 | isempty(addr) addr='all'; end
if nargin<2 | isempty(numtimes) numtimes=TESTBED.retry; end

%load topology49_1200x1200.mat
%useTopology(topology49_1200x1200);
%TESTBED.anchorNodes=[10 12 16 29];
load nodes25_area33x33m_topology
useTopology(t);
%TESTBED.nodeIDs=31:44;
%TESTBED.anchorNodes=[31 34 41 44];
initTESTBED(addr)
%TESTBED.deadNodes=[15 29 44];
disp('  ')
for i=1:numtimes
  disp('peg reset')
  peg(addr,'reset')
  pause(.5)
end

disp('  ')
pause(1)
for i=1:numtimes
  disp('peg on')
  peg(addr,'on')
  pause(1.5)
end

if(strcmpi(addr,'all'))
  disp('  ')
  disp('turn off extras')
%  turnoff
end


% $$$ % $$$ disp('  ')
% $$$ % $$$ pause(1)
% $$$ % $$$ for i=1:numtimes
% $$$ % $$$   disp('peg RangingMinCount(0)')
% $$$ % $$$   peg(addr,'RangingMinCount',0)
% $$$ % $$$   pause(.5)
% $$$ % $$$ end
% $$$ % $$$ 
% $$$ % $$$ disp('  ')
% $$$ % $$$ pause(1)
% $$$ % $$$ for i=1:numtimes
% $$$ % $$$   disp('peg debugAddr(65535)')
% $$$ % $$$   peg(addr,'debugAddr',65535)
% $$$ % $$$   pause(.5)
% $$$ % $$$ end

disp('  ')
for i=1:numtimes
  disp('peg service(50)')
  peg(addr,'service',50)
  pause(.5)
end

% $$$ disp(' ')
% $$$ for i=1:numtimes
% $$$   disp('peg RangingDebug(1)')
% $$$   peg(addr,'RangingDebug',1)
% $$$   pause(.5)
% $$$ end

% $$$ disp(' ')
% $$$ for i=1:numtimes
% $$$   disp('peg diagMsgOn(1)')
% $$$   peg(addr,'diagMsgOn',1)
% $$$   pause(.5)
% $$$ end

% $$$ TESTBED.rangingCountMin=4;
% $$$ disp(' ')
% $$$ for i=1:numtimes
% $$$    disp(['peg RangingCountMin(' num2str(TESTBED.rangingCountMin) ')'])
% $$$    peg(addr,'RangingCountMin',TESTBED.rangingCountMin)
% $$$    pause(.5)
% $$$ end


TESTBED.rfPower=1;
disp(' ')
for i=1:numtimes
  disp(['peg calamariRFPower(' num2str(TESTBED.rfPower) ')'])
  peg(addr,'calamariRFPower',TESTBED.rfPower)
  pause(.5)
end

TESTBED.RssiRangingScale=3.73;
disp(' ')
for i=1:numtimes
  disp(['peg RssiRangingScale(' num2str(TESTBED.RssiRangingScale) ')'])
  peg(addr,'RssiRangingScale',TESTBED.RssiRangingScale)
  pause(.5)
end

TESTBED.RssiRangingBias=345;
disp(' ')
for i=1:numtimes
  disp(['peg RssiRangingBias(' num2str(TESTBED.RssiRangingBias) ')'])
  peg(addr,'RssiRangingBias',TESTBED.RssiRangingBias)
  pause(.5)
end

disp(' ')
for i=1:numtimes
  disp(['peg intiateSchedule(0)'])
  peg(addr,'initiateSchedule',0)
  pause(.5)
end

% $$$ TESTBED.maxAnchorRank=65535; %no max for now
% $$$ disp(' ')
% $$$ for i=1:numtimes
% $$$ disp(['peg maxAnchorRank(' num2str(TESTBED.maxAnchorRank) ')'])
% $$$ peg(addr,'maxAnchorRank',TESTBED.maxAnchorRank)
% $$$ pause(.5)
% $$$ end
% $$$ 
% $$$ disp(' ')
% $$$ for i=1:numtimes
% $$$ disp(['peg RSSIRangingScale(1)'])
% $$$ peg(addr,'RSSIRangingScale',1)
% $$$ pause(.5)
% $$$ end
% $$$ 
% $$$ disp(' ')
% $$$ for i=1:numtimes
% $$$ disp(['peg RSSIRangingBias(0)'])
% $$$ peg(addr,'RSSIRangingBias',0)
% $$$ pause(.5)
% $$$ end


% $$$ TESTBED.exchangeTimeout=16000;
% $$$ TESTBED.exchangeMask= 8095;
% $$$ TESTBED.exchangeRetry=3;
% $$$ TESTBED.exchangeRetryTimeout=2047;
% $$$ TESTBED.anchorExchangeTimeout=8095;
% $$$ disp(' ')
% $$$ for i=1:numtimes
% $$$   disp(['peg all RangingExchangeParameters(' num2str(TESTBED.exchangeTimeout) ', '  num2str(TESTBED.exchangeMask) ', '  num2str(TESTBED.exchangeRetry) ', '  num2str(TESTBED.exchangeRetryTimeout) ', ' num2str(TESTBED.anchorExchangeTimeout)  ')'])
% $$$   peg('all','RangingExchangeParameters',TESTBED.exchangeTimeout, TESTBED.exchangeMask, TESTBED.exchangeRetry, TESTBED.exchangeRetryTimeout,TESTBED.anchorExchangeTimeout) 
% $$$   pause(.5)
% $$$ end

TESTBED.numChirps=10;
% $$$ disp(' ')
% $$$ for i=1:numtimes
% $$$   disp(['peg all RangingParameters(1, ' num2str(TESTBED.numChirps) ', 500, 127, 10, 20)'])
% $$$   peg('all','RangingParameters',1, TESTBED.numChirps, 500, 127, 10, 20)
% $$$   pause(.5)
% $$$ end

% $$$ TESTBED.rangingStartDelayBase=1024;
% $$$ TESTBED.rangingStartDelayMask=1023;
% $$$ disp(' ')
% $$$ for i=1:numtimes
% $$$   disp(['peg all RangingStartDelay(' num2str(TESTBED.rangingStartDelayBase) ', ' num2str(TESTBED.rangingStartDelayMask) ')'])
% $$$   peg('all','RangingStartDelay',TESTBED.rangingStartDelayBase, TESTBED.rangingStartDelayMask)
% $$$   pause(.5)
% $$$ end
% $$$ 
% $$$ disp(' ')
% $$$ for i=1:numtimes
% $$$   disp('peg all exchangeRanging(0)')
% $$$   peg('all','exchangeRanging',0)
% $$$   pause(.5)
% $$$ end

% $$$ disp(' ')
% $$$ for i=1:numtimes
% $$$   disp('peg deltaDistanceThreshold(65535)')
% $$$   peg all deltaDistanceThreshold(65535)
% $$$   pause(.5)
% $$$ end

% $$$ disp(' ')
% $$$ for i=1:numtimes
% $$$   disp('peg all txDelay(800)')
% $$$   peg('all','txDelay',800)
% $$$   pause(.5)
% $$$ end

TESTBED.txDelay=127;
disp(' ')
 for i=1:numtimes
   disp(['peg all txDelay(' num2str(TESTBED.txDelay) ')'])
   peg('all','txDelay',TESTBED.txDelay)
   pause(.5)
 end
 
 TESTBED.txDelayMask=127;
 disp(' ')
 for i=1:numtimes
   disp(['peg all txDelayMask(' num2str(TESTBED.txDelayMask) ')'])
   peg('all','txDelayMask',TESTBED.txDelayMask)
   pause(.5)
 end
 
% $$$  TESTBED.txRetry=3;
% $$$  disp(' ')
% $$$  for i=1:numtimes
% $$$    disp(['peg all txRetry(' num2str(TESTBED.txRetry) ')'])
% $$$    peg('all','txRetry',TESTBED.txRetry)
% $$$    pause(.5)
% $$$  end

% $$$ disp(' ')
% $$$ for i=1:numtimes
% $$$   disp('peg all medianTube(1)')
% $$$   peg('all','medianTube',1)
% $$$   pause(.5)
% $$$ end
% $$$ 
% $$$ disp(' ')
% $$$ for i=1:numtimes
% $$$   disp('peg all RangingScale(34)')
% $$$   peg('all','RangingScale',34)
% $$$   pause(.5)
% $$$ end

% $$$ disp(' ')
% $$$ for i=1:numtimes
% $$$   disp('peg all RangingScale(34)')
% $$$   peg('all','RangingScale',34)
% $$$   pause(.5)
% $$$ end

% $$$ disp(' ')
% $$$ for i=1:numtimes
% $$$   disp('peg all PositionDebug(1)')
% $$$   peg('all','PositionDebug',1)
% $$$   pause(.5)
% $$$ end

% $$$ disp('  ')
% $$$ disp('peg ident')
% $$$ peg(addr,'ident')
% $$$ pause(.5)
% $$$ 
% $$$ disp('  ')
% $$$ disp('peg service')
% $$$ peg(addr,'service')
% $$$ pause(.5)

%if ~strcmp(addr,'all')
  setLocationInfo(addr)
%  setRanging(addr,4)
%end

%disp('  ')
%disp('rangeOnce(??,3)')
%rangeOnce(addr,3)

getReport('service')



