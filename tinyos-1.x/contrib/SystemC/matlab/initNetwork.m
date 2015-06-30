function initNetwork(serviceNum)
global nodes;
RETRY=3;

disp('Resetting nodes');
for i=1:RETRY
    peg all reset;
    pause(1);
end

disp('Turning nodes on');
for n=1:length(nodes.realID)
    for i=1:RETRY
        cmd = ['peg ' nodes.realID(n,:) ' on'];
        eval(cmd);
        pause(0.5);
    end
end

disp(['Starting service ' num2str(serviceNum) ' on nodes']);
for i=1:RETRY
    cmd = ['peg all service(' num2str(serviceNum) ')']
    eval(cmd)
    pause(1);
end
