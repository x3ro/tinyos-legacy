function queryAnchors
global nodes;
RETRY=2;

for i=1:length(nodes.realID)
    for j=1:RETRY    
        cmd = ['peg ' nodes.realID(i,:) ' CalamariReportAnchors']
        eval(cmd)
        pause(0.25);
    end
end
