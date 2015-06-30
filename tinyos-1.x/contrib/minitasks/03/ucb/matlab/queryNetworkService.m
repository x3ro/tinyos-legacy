function queryNetworkService
global nodes;
disp('Ping node service');
for i=1:length(nodes.realID)
    cmd = ['peg ' nodes.realID(i,:) ' service']
    eval(cmd)
    pause(0.5);
end