function testSN
% Tests whether the Sensor Network Simulator is reasonable

runThis = input('WARNING: modifies P,E and SN.  Continue? (1 or 0)');
if runThis
    global P;
    global E;
    global SN;
    global T;
    T = 1; % dummy value
    load('examples/SNtest_SN');

    load('examples/SNtest_PE1');
    [delay packets] = SNSim_ralpha;
    disp(sprintf('Scenario 1: expected=%s actual=%d',expected,delay));
    packets
    
    load('examples/SNtest_PE2');
    [delay packets] = SNSim_ralpha;
    disp(sprintf('Scenario 2: expected=%s actual=%d',expected,delay));
    packets

    load('examples/SNtest_PE3');
    [delay packets] = SNSim_ralpha;
    disp(sprintf('Scenario 3: expected=%s actual=%d',expected,delay));
    packets

    load('examples/SNtest_PE4');
    [delay packets] = SNSim_ralpha;
    disp(sprintf('Scenario 4: expected=%s actual=%d',expected,delay));
    packets

    load('examples/SNtest_PE5');
    [delay packets] = SNSim_ralpha;
    disp(sprintf('Scenario 5: expected=%s actual=%d',expected,delay));
    packets

    load('examples/SNtest_PE6');
    [delay packets] = SNSim_ralpha;
    disp(sprintf('Scenario 6: expected=%s actual=%d',expected,delay));
    packets

    load('examples/SNtest_PE7');
    [delay packets] = SNSim_ralpha;
    disp(sprintf('Scenario 7: expected=%s actual=%d',expected,delay));
    packets

end
