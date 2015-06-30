% testOnlineTracking
% script for testing that startOnlineTracking works
% when using default values

global TEST_MTT MTT;

cfgfile = 'RFS36wired.cfg';
startOnlineTracking(cfgfile,0);
TEST_MTT.file = 'RFS36wired_8202005_walk1.mat';
a = load(TEST_MTT.file);
TEST_MTT.reportMat = a.dataStructure;

%make best effort to insert non-timesynced messages
nonZero = find(TEST_MTT.reportMat(7,:) ~= 0);
if (TEST_MTT.reportMat(7,1) == 0)
    nonZero = [1 nonZero]; %add index 1, to allow interpolation from 1st reading
    %set artificial first time
    TEST_MTT.reportMat(7,1) = TEST_MTT.reportMat(7,nonZero(2)) - 0.001*nonZero(2);
end
if (TEST_MTT.reportMat(7,end) == 0)
    lastInd = size(TEST_MTT.reportMat,2);
    nonZero = [nonZero lastInd]; %add index 1, to allow interpolation from 1st reading
    %set artificial last time
    TEST_MTT.reportMat(7,lastInd) = TEST_MTT.reportMat(7,nonZero(end-1)) + 0.001*(lastInd - nonZero(end-1));
end

for i = 1:length(nonZero)-1
    lowerInd = nonZero(i);
    upperInd = nonZero(i+1);
    step = (TEST_MTT.reportMat(7,upperInd) - TEST_MTT.reportMat(7,lowerInd))/(upperInd - lowerInd);
    timeArr = TEST_MTT.reportMat(7,lowerInd):step:TEST_MTT.reportMat(7,upperInd);
    % not sure if calculation of timeArr is robust to roundoff errors
    TEST_MTT.reportMat(7,lowerInd:upperInd) = timeArr;
end


lastT = TEST_MTT.reportMat(7,end)/65536; % Matlab timestamp conversion to seconds
firstT = TEST_MTT.reportMat(7,1)/65536; % Matlab timestamp conversion to seconds
TEST_MTT.numExecute = ceil((lastT-firstT)/MTT.period);

TEST_MTT.timer = timer('TimerFcn','testOnlineTracking_helper', ...
                      'ExecutionMode','fixedRate',...
                      'Period', MTT.period,'TasksToExecute',TEST_MTT.numExecute);
start(TEST_MTT.timer);
