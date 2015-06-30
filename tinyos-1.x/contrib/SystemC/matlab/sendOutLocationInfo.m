function sendOutLocationInfo
global nodes;
RETRY=3;

for i=1:length(nodes.realID)
    for j=1:RETRY    
%        cmd = ['peg ' nodes.realID(i,:) ' MyRangingId(' num2str(nodes.rangingID(i)) ')']
%        eval(cmd)
%        pause(0.25);
        cmd = ['peg ' nodes.realID(i,:) ' LocationInfo(' num2str(nodes.anchor(i)) ',' ...
               num2str(nodes.X(i)) ',' num2str(nodes.Y(i)), ')']
        eval(cmd)
        pause(0.25);
    end
end
