function ret = tstestinit(nodes, root, power, basedir)
global ststatus_fired_arg_nodes;
global ststatus_fired_i;
global ststatus_TIMER;
global BASEDIR;

BASEDIR = basedir;

    for j = 1:3
        peg all reset;
        pause(1);
        
    end
    for j = 1:3
        peg all on
        pause(1)
    end
    for j=1:3
        peg all backoffBase(35)
        peg all backoffMask(127)
        pause(1)
    end
    
    for j=1:3
        peg('all','rfpower',power)
        pause(1)
    end
    for j=1:3
        peg all service(30)
        pause(1)
    end
    
    for i=1:1
        peg(root,'rtbuild');
        pause(1);    
    end
        
    for j=1:3
        peg all rfpower(255)
        pause(1)
    end

    ststatus_fired_i = 0;
    ststatus_fired_arg_nodes = nodes;
    ststatus_TIMER = timer('TimerFcn','ststatus_fired;','Period',0.5,'ExecutionMode','fixedSpacing');
    start(ststatus_TIMER);
    ret = 1;
    
