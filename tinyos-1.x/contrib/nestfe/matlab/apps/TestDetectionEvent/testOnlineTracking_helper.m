function testOnlineTracking_helper
% Do not call this function directly.
% See 'testOnlineTracking' for more details.

global TEST_MTT MTT;

offset = 0.5; %offset for grouping observations: big difference on outcome

n = get(TEST_MTT.timer,'TasksExecuted'); %Number of time intervals that have passed
if (n == TEST_MTT.numExecute)
    disp('Last data point of testOnlineTracking.  Run "stopOnlineTracking".');
end
pseudoT = (n-offset)*MTT.period;

t = TEST_MTT.reportMat(7,:)/65536; % Matlab timestamp conversion to seconds
%t = [60*60 60 1]*TEST_MTT.dataStructure(7:9,:); % Matlab timestamp conversion to seconds
t = t - t(1); %normalize to starting at t = 0

dataIndex = find((t <= pseudoT) & (t > (pseudoT - MTT.period)));
MTT.reportMat = [MTT.reportMat TEST_MTT.reportMat(:,dataIndex)];
