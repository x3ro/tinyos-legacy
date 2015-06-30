pursuerEvaderReceivePackets.m have been modified to accomodate the estimation algorithms

in initializePursuerEvader.m I made the following major modifications

global trackingHistoryLength;%this is the number of past positions of the pursuer/evader that we graph
trackingHistoryLength=50 ;
global measurementHistoryLength;%this is the number of history measurements to use for current estimate
measurementHistoryLength=1;
global timeDelay  %time delay in second of received packets 
timeDelay = 0;
global samplesPerRegression %number of past samples used for regression
samplesPerRegression = 4;
global METHOD % linear or cubic regression
METHOD = 'linear'; 

T0 = clock;  %get current time
TPLOT = T0;  % in case we want to plot no more that one plot per second

in pursuerEvaderReceivePackets.m I made the following modification:

timeStamp = etime(clock,T0);  %get time at arrival on matlab relative to T0 in seconds




