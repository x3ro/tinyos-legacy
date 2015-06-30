function rangeOnce(addr, numChirps)

global TESTBED
global RANGE_ONCE


%LOOP INITIALIZE
if nargin>0  

  %parse parameters
  if nargin<2 | isempty(numChirps) numChirps=4; end
  
  %initialize state machine state
  if strcmp(addr,'all')
    state.addr= TESTBED.id;
  else
    state.addr=addr;
  end
  state.index=1;
  
  %initialize timer
  if ~isfield(TESTBED,'timer') | isempty(TESTBED.timer)
    TESTBED.timer = timer('Name', 'TESTBED Timer','ExecutionMode','fixedRate');
    %start(CHIPCON.timer) %use the "play" button on the gui to start the timer
  end

  %set all the ranging parameters
  disp(['peg all RangingParameters(2, ' num2str(numChirps) ', 512, 512, 5000, 20)'])
  peg('all','RangingParameters',2, numChirps, 512, 512, 5000, 20)

  %save the state in RANGE_ONCE.state and start the timer
  RANGE_ONCE.state=state;
  set(TESTBED.timer,'TimerFcn', 'rangeOnce', 'StartDelay',1,'Period', numChirps,'ExecutionMode','fixedRate');
  start(TESTBED.timer)

else

  %LOOP TERMINATE
  if RANGE_ONCE.state.index>length(RANGE_ONCE.state.addr)
    stop(TESTBED.timer)
    %reset the node's ranging parameters
    disp(['peg all RangingParameters(2, 10, 512, 512, 5000, 20)'])
    peg('all','RangingParameters',2, 10, 512, 512, 5000, 20)
    
    return
  end
    
  %LOOP CONTENT
  %make it chirp and increment state
  disp(['peg ' num2str(RANGE_ONCE.state.addr(RANGE_ONCE.state.index)) ' CalamariRangeOnce']) 
  peg(RANGE_ONCE.state.addr(RANGE_ONCE.state.index), 'CalamariRangeOnce') 
  RANGE_ONCE.state.index=RANGE_ONCE.state.index+1;

end



