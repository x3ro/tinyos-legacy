function ret = tstestrun(pairs, number, modes, basedir)
    global fired_arg_pairs
    global fired_arg_number
    global fired_arg_modes
    global fired_arg_basedir
    global fired_i
    global fired_j
    global fired_k
    global fired_STATE_POINT
    global fired_TIMER
    global RouteTimings
    global Experiment
    
    RouteTimings = [];
    Experiment = [];

    fired_arg_pairs = pairs;
    fired_arg_number = number;
    fired_arg_modes = modes;
    fired_arg_basedir = basedir;
    fired_k = 1;
    fired_STATE_POINT = 0;
    fired_TIMER = timer('TimerFcn','fired;','Period',1.75,'ExecutionMode','fixedSpacing');
    start(fired_TIMER)
    ret = fired_TIMER;

