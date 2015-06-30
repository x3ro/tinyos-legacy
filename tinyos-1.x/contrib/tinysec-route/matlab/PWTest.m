function PWTest(basedir, nodes, pktlength, duration)

global PWStack;

PWStack.arg.basedir = basedir;
PWStack.arg.nodes = nodes;
PWStack.arg.pktlength = pktlength;
PWStack.arg.duration = duration;
PWStack.STATE = 1;
PWStack.i = 1;

PWStack.TIMER = timer('TimerFcn','PWTestAsync;','Period',.25,'ExecutionMode','fixedSpacing');
start(PWStack.TIMER)
ret = PWStack.TIMER;
