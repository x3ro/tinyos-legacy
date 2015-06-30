% testOnlineTracking
% script for testing that startOnlineTracking works
% when using default values

global TEST_MTT MTT;

startOnlineTracking;
TEST_MTT.file = 'hmttsn_testbed/MAGMHOPRPT_1202005_6.mat';
a = load(TEST_MTT.file);
a = a.dataStructure.reportMat;
t = [60*60 60 1]*a(7:9,:); % Matlab timestamp conversion to seconds
t = t - t(1) %normalize to starting at t = 0

TEST_MTT.numExecute = ceil(t(end)/MTT.period);

TEST_MTT.timer = timer('TimerFcn','testOnlineTracking_helper', ...
                       'ExecutionMode','fixedRate',...
                       'Period', MTT.period,'TasksToExecute',TEST_MTT.numExecute);
start(TEST_MTT.timer);
