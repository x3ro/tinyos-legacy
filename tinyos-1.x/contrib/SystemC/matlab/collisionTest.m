function collisionTest(distance)
global COLLISION

%when called by user, they must pass the distance as a param
if ((~isfield(COLLISION,'distances') & nargin<1) | (COLLISION.count==0 & nargin<1))
    error('What distance is the independant node at?')
end
%when called by the user, remember the distance that they pass
if nargin==1
    COLLISION.distances(end+1)=distance;
    COLLISION.count=1;
else
    %when called by the timer, record that we've been called again
	COLLISION.count=COLLISION.count+1;
end

%if this is the very very first time this is called, turn on debug and
%instantiate the timer
if ~isfield(COLLISION,'t')
	peg('all', 'RangingDebug(1)');
	peg('all', 'RangingDebug(1)');
	peg('all', 'RangingDebug(1)');
    COLLISION.t=timer('TimerFcn', 'collisionTest', 'StartDelay', 2, 'Period', 2, 'ExecutionMode', 'fixedRate');
end

%if the nodes have not chirped 10 times for this distance, chirp again
if COLLISION.count<10
    peg('all', 'CalamariRangeOnce');
end

%if this is the first time the command is being called for this distance,
%start the timer
if COLLISION.count==1
    start(COLLISION.t);
elseif COLLISION.count>=10
    %if this is the last time the command is being called for this
    %distance, stop the timer.
    COLLISION.count=0;
    stop(COLLISION.t);
end  