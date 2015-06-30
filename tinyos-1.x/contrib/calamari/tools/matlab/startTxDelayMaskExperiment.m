function startTxDelayMaskExperiment(delay)
global TESTBED
addr='all';
numtimes=TESTBED.retry;

load topology49_1200x1200.mat
useTopology(topology49_1200x1200);
initTESTBED(addr)
TESTBED.deadNodes=[15 29 44];
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
  turnoff
end

disp('  ')
for i=1:numtimes
disp('peg service(50)')
peg(addr,'service',50)
pause(.5)
end

TESTBED.rfPower=255;
disp(' ')
for i=1:numtimes
disp(['peg calamariRFPower(' num2str(TESTBED.rfPower) ')'])
peg(addr,'calamariRFPower',TESTBED.rfPower)
pause(.5)
end

TESTBED.maxAnchorRank=65535; %no max for now
disp(' ')
for i=1:numtimes
disp(['peg maxAnchorRank(' num2str(TESTBED.maxAnchorRank) ')'])
peg(addr,'maxAnchorRank',TESTBED.maxAnchorRank)
pause(.5)
end

TESTBED.txDelay=75;
disp(' ')
for i=1:numtimes
  disp(['peg all txDelay(' num2str(TESTBED.txDelay) ')'])
  peg('all','txDelay',TESTBED.txDelay)
  pause(.5)
end

TESTBED.txRetry=4;
disp(' ')
for i=1:numtimes
  disp(['peg all txRetry(' num2str(TESTBED.txRetry) ')'])
  peg('all','txRetry',TESTBED.txRetry)
  pause(.5)
end

if ~strcmp(addr,'all')
  setLocationInfo(addr)
  setRanging(addr)
else 
  setRanging
  
  setLocationInfo
  
end

TESTBED.txDelayMask=delay;
disp(' ')
for i=1:numtimes
  disp(['peg all txDelayMask(' num2str(TESTBED.txDelayMask) ')'])
  peg('all','txDelayMask',TESTBED.txDelayMask)
  pause(.5)
end
  
disp(' ')
for i=1:numtimes
  disp(['peg all CalamariShortestPath '])
  peg all CalamariShortestPath
  pause(.5)
end


